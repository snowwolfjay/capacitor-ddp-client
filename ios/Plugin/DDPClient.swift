//
//  DDPClient.swift
//  ByCapLocation
//
//  Created by byroot on 2022/6/21.
//

import Foundation
import Starscream
import Capacitor

enum DDPClientState {
    case   EMPTY
    case   CREATING
    case   CONNECTING
    case   CONNECTED
    case   NEGOING
    case   READY
    case   LOGING
    case   LOGINED
}

public class DDPClient: WebSocketDelegate{
    var lastState = DDPClientState.EMPTY;
    var state = DDPClientState.EMPTY;
    var ddpServer="";
    var socket:WebSocket?;
    var account:Account!;
    var waitingCalls : [DDPClientMethodCall] = [];
    var pendingCalls : [DDPClientMethodCall] = [];
    var subs : [DDPSubscriber] = [];
    var timer:Timer?;
    public var isForground = true;
    public func setup(server:String){
        self.account = Account(self)
        ddpServer = server;
        createSocket()
    }
    private func setState(_ ns:DDPClientState){
        if ns == state {
            return
        }
        lastState = state
        state = ns;
        onStateChange(nv: state, ov: lastState)
    }
    private func canSendCall(_ call :DDPClientMethodCall)-> Bool{
        if [DDPClientState.READY,DDPClientState.LOGINED,DDPClientState.LOGING].contains(where: {$0 == state}) == false {
            nativeLog("not ready")
            return false
        }
        if call.needLogin && (self.state != DDPClientState.LOGINED ){
            nativeLog("not login")
            return false
        }
        return true
    }
    private func onStateChange(nv:DDPClientState,ov:DDPClientState){
        nativeLog("State change from \(ov) -> \(nv)")
        //      ready - send calls and try relogin
        if nv == DDPClientState.READY {
            self.flushWaitingCall()
            if account.hasLogin {
                self.login();
            }
            return
        }
        //      when disconnect try reconnect with 5s time delay
        if nv == DDPClientState.EMPTY {
            self.timer?.invalidate()
            let timer1 = Timer.scheduledTimer(withTimeInterval:5, repeats: false, block: { (a1 :Any) in
                nativeLog("timeeeerrrrrr")
                self.timer = nil
                self.createSocket()
            })
            RunLoop.current.add(timer1, forMode: RunLoopMode.commonModes)
            self.timer = timer1
            return
        }
        //      send call those need login first
        if nv == DDPClientState.LOGINED {
            self.flushWaitingCall();
            let s = DDPSubscriber.subCall(self)
            self.subscribe(s)
            return
        }
    }
    private func createSocket(){
        if state != DDPClientState.EMPTY || ddpServer == "" {
            return
        }
        setState(DDPClientState.CREATING)
        var request = URLRequest(url: URL(string:self.ddpServer)!)
        request.timeoutInterval = 5
        let soc = WebSocket(request: request)
        soc.delegate = self
        soc.connect()
        self.socket = soc;
        setState(DDPClientState.CONNECTING)
    }
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            onConnected()
            nativeLog("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            onDisconnect()
            nativeLog("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            nativeLog("Received text: \(string)")
            if let data = string.data(using: .utf8) {
                do {
                    let data = try JSONSerialization.jsonObject(with: data)
                    if let dict = data as? [String:Any]{
                        if let msg = dict["msg"] as? String {
                            nativeLog(msg)
                            if msg == "connected" {
                                setState(DDPClientState.READY)
                                return
                            }
                            if msg == "ping" {
                                client.write(string:"{\"msg\":\"pong\"}")
                                return
                            }
                            if msg == "result" {
                                if let id = dict["id"] as? String {
                                    nativeLog("Handle result \(id)")
                                    self.handlePendingCall(id: id, success: dict["error"] as? String == nil, data: dict["result"])
                                }
                                
                                return
                            }
                            if msg == "added" {
                                if let fields = dict["fields"] as? [String:Any] {
                                    print(fields)
                                    if let caller = fields["callerName"] as? String {
                                        if let kind = fields["kind"] as? Int {
                                            if(!self.isForground){
                                                showCallNotify(caller,kind )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch{
                    
                }
            }
            break
        case .binary(let data):
            nativeLog("Received data: \(data.count)")
            break
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            onDisconnect()
            break
        case .cancelled:
            onDisconnect()
        case .error(let error):
            print(error ?? "unknow error")
            onDisconnect()
            //            NSLog([,],error.debugDescription <#T##args: CVarArg...##CVarArg#>)
        }
    }
    private func onConnected(){
        setState(DDPClientState.CONNECTED)
        startNego()
    }
    private func onDisconnect(){
        setState(DDPClientState.EMPTY)
        flushPendingCall()
    }
    private func startNego(){
        if let soc = self.socket {
            setState(DDPClientState.NEGOING)
            soc.write(string: "{\"msg\":\"connect\",\"version\":\"1\",\"support\":[\"1\",\"pre2\",\"pre1\"]}", completion: { ()->Void in
                nativeLog("ddp connect message sented")
            })
        }
    }
    private func handlePendingCall(id:String,success:Bool,data:Any?){
        var call:DDPClientMethodCall?;
        for cal in pendingCalls {
            if cal.id == id {
                call = cal;
                break
            }
        }
        let result:Any =  data ?? ""
        nativeLog( String(pendingCalls.count ))
        nativeLog((call == nil) ? "find":"emp")
        if call != nil {
            nativeLog("Call \(call!.name) has result \(success) \(result)")
            if success {
                call?.onSuccess(result)
            } else {
                call?.onFail(result)
            }
        }
    }
    private func flushPendingCall(){
        if self.pendingCalls.isEmpty {
            return
        }
        for cal in self.pendingCalls {
            cal.onFail("disconnect")
        }
        self.pendingCalls.removeAll()
    }
    private func flushWaitingCall(){
        if(waitingCalls.isEmpty){
            return
        }
        var unused:[DDPClientMethodCall] = []
        print(waitingCalls.count)
        for ind in 0...waitingCalls.count-1 {
            let cal = self.waitingCalls[ind]
            if self.canSendCall(cal){
                self.execCall(call: cal)
            } else{
                unused += [cal]
            }
        }
        waitingCalls.removeAll()
        waitingCalls += unused;
    }
    private func execCall(call:DDPClientMethodCall){
        if let str = call.pack(){
            pendingCalls += [call]
            self.sendString(str)
        } else {
            nativeLog("no valid string packed \(call.name)")
        }
    }
    public func subscribe(_ s:DDPSubscriber){
        if let str = s.pack(true){
            self.sendString(str)
        } else {
            nativeLog("no valid string packed \(s.name)")
        }
    }
    public func callMethod(call:DDPClientMethodCall){
        if(!self.canSendCall(call)){
            self.waitingCalls += [call]
            nativeLog("cached call \(call.name)")
            return
        }
        nativeLog("call ---- \(call.name)")
        execCall(call: call)
    }
    public func sendString(_ str:String){
        if let soc = self.socket {
            nativeLog(str)
            soc.write(string:str)
        } else{
            nativeLog("no socket setuped")
        }
    }
    public func login(call:DDPClientMethodCall,token:String){
        let oldSuccess = call.onSuccess;
        let oldFail = call.onFail;
        call.onSuccess = { (res:Any) in
            if let d = res as? Dictionary<NSString,Any> {
                if let id = d["id"] as? String{
                    self.account.onLogin(id, token)
                    self.setState(DDPClientState.LOGINED)
                }
                oldSuccess(res)
            }
        }
        call.onFail = { (err:Any) in
            oldFail(err)
            self.account.onLogout()
        }
        self.callMethod(call: call)
    }
    public func login(){
        if account.token == "" {
            return
        }
        let cal = DDPClientMethodCall.buildLoginCall(token: account.token)
        self.login(call:cal,token:account.token)
    }
    public func logout(){
        let call = DDPClientMethodCall.buildLogoutCall();
        account.onLogout()
        callMethod(call: call)
    }
    
    deinit {
        timer?.invalidate()
    }
}
