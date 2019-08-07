//
//  SendBirdClient.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation
import SendBirdSDK

#if targetEnvironment(simulator)
    let isSimulator = true
#endif

let ErrorDomainConnection = "com.sendbird.sample.connection"
let ErrorDomainUser = "com.sendbird.sample.user"

class SendBirdClient: ClientProtocol {

    class func shared() -> SendBirdClient {
        return sendbirdClient
    }

    private static var sendbirdClient: SendBirdClient = {
        let client = SendBirdClient()
        return client
    }()

    init() { }
    
    
    
    // MARK: - Public
    
    var isConnected: Bool {
        return SBDMain.getConnectState() == .open //Connection Opened
    }
    
    func connectClient(connectionRequest:ConnectionRequest, success: @escaping ConnectionSucceeded, failure:  @escaping MessageCenterFailureCompletion) {
        // If already connected, return success.
        if self.isConnected {
            success("")
            return
        }
        var userId : String?
        var errorCode : Int?
        var errorMessage : String?
        
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async {
            SBDMain.initWithApplicationId(connectionRequest.appId)
            SBDMain.connect(withUserId: connectionRequest.userId, accessToken: connectionRequest.accessToken, completionHandler: { (user, error) in
                // If Error is not nil
                if let err = error {
                    errorCode = err.code
                    errorMessage = err.localizedDescription
                    group.leave()
                    return
                }
                // If some how, user object is not returned.
                guard let user = user else {
                    errorCode = -1
                    errorMessage = "user not found"
                    group.leave()
                    return
                }
                
                userId =  user.userId
                // If a push token registration is pending, get it completed. Re-register
                if let pushToken: Data = SBDMain.getPendingPushToken() {
                    connectionRequest.updatePushToken(pushToken: pushToken)
                    self.registerDevicePushToken(connectionRequest: connectionRequest, completion: nil)
                    //FIXME: Add wait here as well
                    group.leave()
                }
                else {
                    group.leave()
                }
            })
        }
        
        group.notify(queue: .main) {
            guard let userId = userId else {
                if let code = errorCode, let message = errorMessage {
                    failure(code,message)
                }
                else {
                    failure(-1,"")
                }
                return
            }
            success(userId)
        }
        
    }
    
    // MARK: - Public Methods, Exposed to Apps
    // Register user token
    func registerDevicePushToken(connectionRequest:ConnectionRequest, completion: RegisterDevicePushTokenCompletion?) {
        
        var _status : SBDPushTokenRegistrationStatus?
        var _error : Error?
        var _unique = true
        
        if  let unique = connectionRequest.unique {
            _unique = unique
        }
        guard  let token = connectionRequest.pushToken else {
            let error = NSError(domain: "com.pacellc.messagecenter", code: 0, userInfo: nil)
            completion?(nil,error)
            return
        }
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            SBDMain.registerDevicePushToken(token, unique: _unique) { (status, error) in
                _status = status
                _error = error
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            // FIXME: Disconnect
            self?.disconnectClient()
            completion?(_status, _error)
        }
    }
  
    // Unregister user token --
    func unregisterFromSendBird (connectionRequest:ConnectionRequest, completion: @escaping UnregistrationCompletion) {
        
        var error : Error?
        let group = DispatchGroup()
        var unique = true
        
        if let _unique = connectionRequest.unique {
            unique = _unique
        }
        
        guard let token = connectionRequest.pushToken else {
            completion(false)
            return
        }
        
        group.enter()
        DispatchQueue.main.async {
            if unique == false {
                // if unique is true, register deletes all user tokens before registration else it keeps other tokens and registers a new one. So while unregistering if unique is false, we need to delete that specific token only.
                SBDMain.unregisterPushToken(token) { (response, err) in
                    error = err
                    group.leave()
                }
            }
            else {
                SBDMain.unregisterAllPushToken {(response, err) in
                    error = err
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.disconnectClient()
            completion(error == nil)
        }
    }

    
    func getUnReadMessagesCount(connectionRequest:ConnectionRequest, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion) {
        
        var errorCode : Int?
        var errorMessage : String?
        var unreadCount : Int = 0
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            if let channel = connectionRequest.channel {
                SBDGroupChannel.getWithUrl(channel) { (chanelObj, err) in
                    guard err == nil else {
                        errorCode = err?.code
                        errorMessage = err?.localizedDescription
                        group.leave()
                        return
                    }
                    
                    guard let chanelObj = chanelObj else {
                        errorCode = 0
                        errorMessage = ""
                        group.leave()
                        return
                    }
                    unreadCount = Int(chanelObj.unreadMessageCount)
                    group.leave()
                }
            }
            else {
                SBDMain.getTotalUnreadChannelCount() { (count, err) in
                    guard err == nil else {
                        errorCode = err?.code
                        errorMessage = err?.localizedDescription
                        group.leave()
                        return
                    }
                    unreadCount = Int(count)
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.disconnectClient()
            if let code = errorCode, let message = errorMessage {
                failure(code,message)
                return
            }
            success(unreadCount)
        }
    }
    
    //
    func openChatView(connectionRequest:ConnectionRequest, theme: ThemeObject?, success: @escaping OpenChatSuccessCompletion, failure: @escaping OpenChatFailureCompletion) {
        
        guard  let channelId = connectionRequest.channelId else {
            failure(0,"")
            return
        }
        
        var errorCode : Int?
        var errorMessage : String?
        var channel : Any?
        
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            SBDGroupChannel.getWithUrl(channelId) { (_channel, error) in
                if let err = error  {
                    errorCode = err.code
                    errorMessage = err.localizedDescription
                }
                else {
                    channel = _channel
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.disconnectClient()
            if let code = errorCode, let message = errorMessage {
                failure(code,message)
                return
            }
            success(channel as Any)
        }
        
    }
    
    func handleNotification(userInfo: [AnyHashable : Any]) -> Bool {
        if userInfo["sendbird"] != nil {
            let sendBirdPayload = userInfo["sendbird"] as! Dictionary<String, Any>
            let channelType = sendBirdPayload["channel_type"] as! String
            if channelType == "group_messaging" {
                return true
            }
            return false
        }
        return false
    }
    
    
  
    private func openChat(_ channelId: String, theme: ThemeObject?,  completion: @escaping (Any?) -> Void) {
        
    }
}

fileprivate extension SendBirdClient {
    
    // close sendbird socket connection
    func disconnectClient () {
        SBDMain.disconnect {}
    }
    
}
