import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(DDPClientPlugin)
public class DDPClientPlugin: CAPPlugin {
    private var client = DDPClient()

    @objc func connect(_ call:CAPPluginCall) {
        if let ddpUrl = call.getString("ddp") {
            client.setup(server: ddpUrl)
        }else {
            //            client = nil
        }
        bu.scan()
        call.resolve([:])
    }
    @objc func login(_ call:CAPPluginCall){
        if let token = call.getString("token") {
            if token == "logout"{
                call.resolve(["result":"success"])
                return
            }
            
            let cal = DDPClientMethodCall.buildLoginCall(token: token)
            cal.onSuccess = { (res:Any) in
                call.resolve(["result":res])
            }
            cal.onFail = { (err:Any) in
                call.reject("login fail")
            }
            self.client.login(call: cal,token:token)
        }
    }
}
