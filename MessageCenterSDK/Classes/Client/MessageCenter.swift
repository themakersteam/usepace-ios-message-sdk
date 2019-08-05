//
//  MessageCenter.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation
import UserNotifications
import SendBirdSDK

public class MessageCenter {
    
    static var parentVC: UIViewController {
        set { _parentVC = newValue}
        get { return _parentVC! }
    }
    
    public static var themeObject : ThemeObject?
    public static var completionHandler : ((Bool) -> Void)? = nil
    
    static var groupChannelVC = GroupChannelChattingViewController()
    static var client: Client {
        let client = Client()
        return client
    }
    static var  isOpen = false
    static var _parentVC: UIViewController? = nil
    static var oldVC =  UIViewController()
    static var LAST_CLIENT: ClientType = ClientType.sendBird
    static var notificationInboxMessages: NSArray = []
    static var mainApplication: UIApplication? = nil
    static var launchOptions: [UIApplication.LaunchOptionsKey: Any]? = [:]
    static var deviceToken: Data? = nil
    static weak var delegate: MessageCenterDelegate?
    
    
    
    // MARK: - New Methods
    
     public class func registerUserToken(connectionRequest: ConnectionRequest, completion: @escaping RegistrationCompletion) {
        
        self.deviceToken =  connectionRequest.pushToken
        client.getClient(type: connectionRequest.client).connectClient(connectionRequest: connectionRequest, success: { (userId) in
            client.getClient(type: connectionRequest.client).registerDevicePushToken(connectionRequest: connectionRequest, completion: { (status, error) in
                if let _ = error {
                    completion(false)
                    return
                }
                if let s = status {
                    switch s {
                    case .success:
                        completion(true)
                        break
                        
                    case .error:
                        completion(false)
                        break
                        
                    case .pending:
                        completion( false)
                        break
                    default:
                        break
                    }
                
                }
            })
        }) { (code, error) in
            completion(false)
        }
    }
    
   public class func unregisterUserToken(connectionRequest: ConnectionRequest,unique: Bool, token:NSData, completion: @escaping UnregistrationCompletion) {
        self.client.getClient(type: connectionRequest.client).connectClient(connectionRequest: connectionRequest, success: { (userId) in
            client.getClient(type: connectionRequest.client).unregisterFromSendBird(connectionRequest: connectionRequest, completion: { (status) in
                completion(status)
            })
        }) { (code, reason) in
            completion(false)
        }
    }
    
    
    public class func getUnReadMessagesCount(connectionRequest: ConnectionRequest, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion) {
        
        client.getClient(type: connectionRequest.client).connectClient(connectionRequest: connectionRequest, success: { (userId) in
            client.getClient(type: connectionRequest.client).getUnReadMessagesCount(connectionRequest: connectionRequest, success: { (count) in
                success(count)
                
            }, failure: { (code, message) in
                failure(code,message)
                
            })
            
        }) { (code, reason) in
            failure(code,reason)
            
        }
    }
    
    
    public class func createThemeObject(title: String?, subtitle: String?, welcomeMessage: String? ,primaryColor: UIColor? , primaryAccentColor: UIColor?, primaryNavigationButtonColor: UIColor?, primaryBackgroundColor: UIColor?, primaryActionIconsColor: UIColor?, enableCalling: Bool = false) -> ThemeObject {
        self.themeObject = ThemeObject(title: title,
                                       subtitle: subtitle,
                                       welcomeMessage: welcomeMessage,
                                       primaryColor: primaryColor,
                                       primaryAccentColor: primaryAccentColor,
                                       primaryButtonColor: primaryActionIconsColor,
                                       primaryBackgroundColor: primaryBackgroundColor,
                                       primaryActionIconsColor: primaryActionIconsColor,
                                       primaryNavigationButtonColor: primaryNavigationButtonColor,
                                       enableCalling: enableCalling)
        
        return themeObject! 
    }
    
    public class func openChatView(connectionRequest:ConnectionRequest, theme: ThemeObject?, success: @escaping OpenChatSuccessCompletion, failure: @escaping OpenChatFailureCompletion) {
        if isOpen {
            success("")
            return
        }
        
        
        client.getClient(type: connectionRequest.client).connectClient(connectionRequest: connectionRequest, success: { (userId) in
            client.getClient(type: connectionRequest.client).openChatView(connectionRequest: connectionRequest, theme: theme, success: {(channel) in
                guard let groupChannel = channel as? SBDGroupChannel else {
                    failure(0,"")
                    return
                }
                
                let resourceBundle = Bundle.bundleForXib(GroupChannelChattingViewController.self)
                
                if !isOpen {
                    groupChannelVC = GroupChannelChattingViewController(nibName: "GroupChannelChattingViewController", bundle: resourceBundle)
                    //groupChannelVC = GroupChannelChattingViewController(nibName: "GroupChannelChattingViewController", bundle: resourceBundle)
                }
                groupChannelVC.groupChannel = groupChannel
                groupChannelVC.lastConnectionRequest = connectionRequest
                if theme != nil {
                    groupChannelVC.themeObject = theme
                }
                else {
                    groupChannelVC.themeObject = Constants.defaultTheme()
                }
                
                if isOpen {
                    groupChannelVC.themeObject = theme
                    groupChannelVC.relaodChatView()
                    success(channel)
                    return
                }
                else{
                    isOpen = true
                    oldVC = parentVC
                    let navController = UINavigationController(rootViewController: groupChannelVC)
                    navController.isNavigationBarHidden = false
                    parentVC.present(navController, animated: true, completion: nil)
                }
                
                success(channel)
                
            }, failure: { (code, message) in
                failure(code,message)
            })
        }) { (code, reason) in
            failure(code,reason)
        }
    }
    
//   public class func disconnect(completion: @escaping () -> Void) {
//
//        // client.getClient(type: LAST_CLIENT).disconnect(completion: completion)
//    }
    
    
//   public class func clearNotificationMessages() {
//        notificationInboxMessages = []
//    }
    
//    public static var isConnected : Bool {
//        get {
//            return client.getClient(type: LAST_CLIENT).isConnected
//        }
//    }
    
    public static func setParentVC(vc: UIViewController) {
        parentVC = vc
    }
    
    public class func handleMessageNotification(_ userInfo: [AnyHashable : Any]) -> NotificationModel? {
        
        let handle = client.getClient(type: LAST_CLIENT).handleNotification(userInfo: userInfo)
        if handle == true {
            var message = ""
            guard let sbPayload = userInfo["sendbird"] as? Dictionary<String, Any> else {
                return nil
            }
            
            if sbPayload["message"] as? String != nil {
                message = sbPayload["message"] as! String
            }
            
            guard let sbChannel = sbPayload["channel"] as? Dictionary<String, Any> else {
                return nil
            }
            let channelURL = sbChannel["channel_url"] as! String
            
            guard let sbSender = sbPayload["sender"] as? Dictionary<String, Any> else {
                return nil
            }
            let senderId = sbSender["id"] as! String
            let senderName = sbSender["name"] as! String
            
            let notification = NotificationModel(title: "", message: message, channelId: channelURL, senderId: senderId, senderName: senderName, image: "")            
            return notification
        }
        else {
            return nil
        }
    }
    
    
    
}
