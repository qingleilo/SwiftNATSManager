//
//  NATSManager.swift
//  NATS_Test
//
//  Created by Roben on 2021/6/25.
//

import UIKit


public class NATSManager: NSObject {

    
    @objc public static var ReceiveNATSMessageNotificationKey = "ReceiveNATSMessageNotificationKey"
    @objc public static var shared: NATSManager {
        struct Static {
            static let instance: NATSManager = NATSManager()
        }
        return Static.instance
    }
    
    
    @objc public var host : String = "localhost"
    @objc public var port : Int = 4222
    var connection : ConnectionDelegate = DefaultConnectionDelegate()
    //以subject为key 保存ssid
    var ssidParams : [String:String] = [:]
    var nats : NATS?
    public override init() {
        
    }

    @objc public func config(host:String,port:Int) {
        self.host = host
        self.port = port
    }
    @objc public func connect(){
        NATS.connect(host: host, port: port, connection: connection) { (result) in
            switch result {
            case .success(let success):
                self.nats = success
            case .failure(let fail):
                print(fail)
                
            }
        }
    }
    
    @objc public func disconnect() {
        guard let _  = self.nats else {
            print("连接失败、nats未实例化成功")
            return
        }
        connection.disconnect()
    }
    
    
    
//    @objc public func subscribe(_ subject:String,completion:@escaping (String) -> Void){
//
//        guard let nats = self.nats else {
//            print("连接失败、nats未实例化成功")
//            return
//        }
//        let result = nats.subscribe(subject: subject) { (message) in
//            //MARK:这里接收消息
//            print("(#####接收到的msg:\(message)")
//            /*
//             ▿ Message
//               - id : 8D0F5F7C-5123-47E7-ABA0-87AA5EB1F294
//               - subject : "china.guangdong.shenzhen"
//               - ssid : "1"
//               ▿ replyTo : Optional<String>
//                 - some : "_INBOX.JQN2JTF052VPQK2MY620IH"
//               - bytes : 4
//               - payload : "1111"
//             */
//        }
//        switch result {
//        case .success(let ssid):
//            completion(ssid)
//        default:
//            print("")
//        }
// 
//    }
    
    
    @objc public func subscribe(_ subject:String){

        guard let nats = self.nats else {
            print("连接失败、nats未实例化成功")
            return
        }
        //先判断当前是否已经被订阅过 如果订阅取消订阅
        if let tempSsid = ssidParams[subject] {
            unsubscribe(tempSsid)
            ssidParams.removeValue(forKey: subject)
        }
        let result = nats.subscribe(subject: subject) { (message) in
            //MARK:这里接收消息
            print("(#####接收到的nats Message:\(message)")
           
            let replyTo = message.replyTo ?? ""
            
            let params : NSDictionary = ["subject":message.subject,"ssid":message.ssid,"payload":message.payload,"replyTo":replyTo]
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NATSManager.ReceiveNATSMessageNotificationKey), object:params)
            /*
             ▿ Message
               - id : 8D0F5F7C-5123-47E7-ABA0-87AA5EB1F294
               - subject : "china.guangdong.shenzhen"
               - ssid : "1"
               ▿ replyTo : Optional<String>
                 - some : "_INBOX.JQN2JTF052VPQK2MY620IH"
               - bytes : 4
               - payload : "1111"
             */
        }
        switch result {
        case .success(let ssid):
            ssidParams[subject] = ssid
            //这里记录 ssid
            print("####subject:\(subject)\n####ssid:\(ssid)")
        default:
            print("")
        }
    }
    
    @objc public func unsubscribe(_ subject:String){
        guard let nats = self.nats ,
              let ssid = ssidParams[subject] else {
            print("nats 或 ssid 有问题 ssid=\(ssidParams[subject])")
            return
        }
        nats.unsubscribe(ssid: ssid)
        ssidParams.removeValue(forKey: subject)
    }
    
    @objc public func publish(subject:String ,msg:String) {
        guard let nats = self.nats else {
            print("连接失败、nats未实例化成功")
            return
        }
        nats.publish(subject: subject, payload: msg, replyTo: "")
    }
    
    

}
