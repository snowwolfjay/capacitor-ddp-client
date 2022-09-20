//
//  DDPClientSub.swift
//  App
//
//  Created by byroot on 2022/7/14.
//

import Foundation
import Capacitor

var sid = 10000;

public class DDPSubscriber {
  public let name:String;
  public let params:[String] ;
  private let id = String(sid);

 init( _ sname:String,_  sparams:[String] ) {
    name = sname
    params = sparams
    sid+=1
  }

  public static func  subCall(_ client:DDPClient) ->DDPSubscriber{
    let sub =  DDPSubscriber("webrtc.p2pcall", [] );
    return sub;
  }

public func pack(_ forSub:Bool) ->String? {
    var obj :Dictionary<String,Any> = [:]
    if (forSub) {
        obj["msg"] = "sub"
        obj["name"] = self.name
        obj["id"] = self.id
        obj["params"] = self.params
    } else {
        obj["msg"] = "unsub"
        obj["id"] = self.id
    }
    let data:NSData! = try? JSONSerialization.data(withJSONObject: obj, options: []) as NSData;
    let str = NSString(data: data as Data,encoding: String.Encoding.utf8.rawValue)!;
    print(str)
    return str as String?
  }
}
 

