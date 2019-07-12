//
//  ClientInterface.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation
import SendBirdSDK

// push token registration

public typealias ConnectionSucceeded = (_ userId: String) -> Void

public typealias RegistrationCompletion = (_ status: Bool) -> Void

public typealias UnregistrationCompletion = (_ status: Bool) -> Void

public typealias MessageCenterFailureCompletion = (_ errorCode: Int, _ errorMessage: String) -> Void



public typealias UnReadMessagesSuccessCompletion = (_ unReadMessagesCount: Int) -> Void

public typealias RegisterDevicePushTokenCompletion = (_ status: SBDPushTokenRegistrationStatus?, _ error: Error?) -> Void

public typealias OpenChatFailureCompletion = (_ errorCode: Int, _ errorMessage: String) -> Void
public typealias OpenChatSuccessCompletion = (_ channel: Any) -> Void

protocol ClientProtocol {
    
    // MARK: -
    var isConnected: Bool { get }
    
    // Connect
    func connectClient(connectionRequest:ConnectionRequest, success: @escaping ConnectionSucceeded, failure:  @escaping MessageCenterFailureCompletion)
    
    //Token Registeration
    func registerDevicePushToken(connectionRequest:ConnectionRequest, completion: RegisterDevicePushTokenCompletion?)
    func unregisterFromSendBird (connectionRequest:ConnectionRequest, completion: @escaping UnregistrationCompletion)
    
    // Unread Messages
    func getUnReadMessagesCount(connectionRequest:ConnectionRequest, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion)
    
    // Chat view
    func openChatView(connectionRequest:ConnectionRequest, theme: ThemeObject?, success: @escaping OpenChatSuccessCompletion, failure: @escaping OpenChatFailureCompletion)
    //func closeChatView(completion: @escaping () -> Void)
    
    // Notification handling
    func handleNotification(userInfo: [AnyHashable : Any]) -> Bool
}

protocol MessageCenterDelegate:class {
    func userDidTapCall(forChannel channel: String, success: @escaping (_ phoneNumber: String) -> Void, failure: @escaping (_ errorMessage: String) -> Void)
    func eventDidOccur(forChannel channel: String, event: MessageCenterEvents, userInfo: [AnyHashable: Any])
}
