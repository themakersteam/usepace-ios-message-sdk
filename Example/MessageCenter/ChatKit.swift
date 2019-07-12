//
//  ChatKit.swift
//  HungerStation
//
//  Created by Ahmad Al-Shaikh Hasan on 04/12/2018.
//  Copyright © 2018 Hunger_Station. All rights reserved.
//

import Foundation
import MessageCenter

class ChatKit : NSObject {
    
    static var shared = ChatKit()
    private override init() {}
    private var theme : ThemeObject?
    private var userDefaultService = UserDefaultsService()
    private var sendBirdService = SendBirdService()
    
    var connectionRequest : ConnectionRequest?
    
    private func createTheme (_ title: String, subtitle: String, welcomeMessage: String) {
        
        // Sender bubble color
        let primaryColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        
        // Color for Title, welcome message background (with alpha 0.4) and Send button background
        let primaryAccentColor = UIColor(red: 245.0/255.0, green: 206.0/255.0, blue: 9.0/255.0, alpha: 1.0)
        
        // Back button color
        let primaryNavigationIconColor = UIColor(red: 245.0/255.0, green: 200.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        
        // Chat background color
        let primaryBackgroundColor = UIColor(red: 244.0/255.0, green: 242.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        
        // Action sheet icons, subtitles, and send button color
        let primaryActionIconsColor = UIColor(red: 82.0/255.0, green: 67.0/255.0, blue: 62.0/255.0, alpha: 1.0)
        
        
        theme = MessageCenter.createThemeObject(title: title,
                                                    subtitle: subtitle,
                                                    welcomeMessage: welcomeMessage,
                                                    primaryColor: primaryColor,
                                                    primaryAccentColor: primaryAccentColor,
                                                    primaryNavigationButtonColor: primaryNavigationIconColor,
                                                    primaryBackgroundColor: primaryBackgroundColor,
                                                    primaryActionIconsColor: primaryActionIconsColor)
    }

    
    func connect (_ sendBirdUser: Sendbird, clientType: ClientType, completion: @escaping (_ success: Bool)->()) {
        
        guard let device = userDefaultService.savedDevice , let token = device.deviceToken else {
            completion(self.isConnected())
            return
        }
        
        if  self.isConnected() == false {
            
            //let pushToken = "2121212324rdfdcef".data(using: .utf8)//token
            let pushToken = token
            connectionRequest = ConnectionRequest(appId: sendBirdUser.appId!,
                                                      userId: sendBirdUser.userId!,
                                                      accessToken: sendBirdUser.accessToken!,
                                                      client: clientType,
                                                      unique: false)
            connectionRequest?.updatePushToken(pushToken: pushToken)
            
            
            
            MessageCenter.registerUserToken(connectionRequest: connectionRequest!) { (status) in
                
                completion(status)
            }
            
        }
        
    }
    
    func openChatView (on vc: UIViewController , channel:SendBirdChannel) {
        showChat(vc: vc, channel: channel)
    }
    
    func showChat(vc : UIViewController,channel : SendBirdChannel) {

        guard  let chatUrl = channel.url else { return }

        connectionRequest?.updateChannel(channel: chatUrl)
        connectionRequest?.updateChannelId(channelId: chatUrl)

       print(connectionRequest!)
        
        let title = channel.title ?? ""
        let subtitle = channel.subTitle ?? ""
        let message = channel.welcomeMessage ?? ""
        
        self.createTheme(title, subtitle: subtitle, welcomeMessage: message)
        
        MessageCenter.setParentVC(vc: vc)
        
        IQKeyboardManager.shared.enable = false
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        PaceProgressHUD.addProgressHUDToTop()
        
        MessageCenter.openChatView(connectionRequest: connectionRequest!, theme: theme, success: { (result) in
            PaceProgressHUD.hideProgressHUDFromTop()
        }) { (code, message) in
            PaceProgressHUD.hideProgressHUDFromTop()
            IQKeyboardManager.shared.enable = true
            IQKeyboardManager.shared.enableAutoToolbar  = true
        }
        
        MessageCenter.completionHandler = { (status) in
            // MessageCenter is dismissed.
            IQKeyboardManager.shared.enable = true
            IQKeyboardManager.shared.enableAutoToolbar  = true
        }
        
    }
    
    
    func disconnect () {
//        if  MessageCenter.isConnected {
//            MessageCenter.disconnect {}
//        }
    }
    
    func isConnected () -> Bool {
//        return  MessageCenter.isConnected
        return false
    }
    
    
    func unReadMessagesCount(chatUrl: String?, completion: @escaping(Int)->()) {
        
        if let request = connectionRequest {
            request.updateChannel(channel: chatUrl)
            MessageCenter.getUnReadMessagesCount(connectionRequest: request, success: { (count) in
                completion(count)
            }) { (code, message) in
                completion(0)
            }
        }
    }
    
    func willHandleNotification( dic: NSDictionary) -> Bool {

        let notification = MessageCenter.handleMessageNotification(dic as! [AnyHashable: Any])
        guard notification != nil else {
            // Notification is not from Chat service.
            return false
        }
        
        return true
    }
    
//    func showMessageBanner(_ dic: NSDictionary) {
//        
//        let notificationPayload = NotificationPayload(userInfo: dic as! [AnyHashable : Any])
//        let notification = notificationPayload.createNotificationView()
//        
//        let notification_ = MessageCenter.handleMessageNotification(dic as! [AnyHashable: Any])
//        guard notification_ != nil  else {
//            // Notification is not from Chat service.
//            return
//        }
//        
//        notification.show(
//            withImage: nil,
//            title: " \((notification_?.senderName)!)",
//        message: " \((notification_?.message)!)") {
//
//            self.presentChatView(dic)
//        }
//    }
    
    func presentChatView(_ dic: NSDictionary) {

        let notification = MessageCenter.handleMessageNotification(dic as! [AnyHashable: Any])
        guard let chatNotification = notification else {
            // Notification is not from Chat service.
            return
        }
        let currentController  = UIViewController().currentVC()
        PaceProgressHUD.addProgressHUDToTop()
        sendBirdService.getSendBirdChannel(channelId: chatNotification.channelId ?? "") { [weak self] (result) in
            PaceProgressHUD.hideProgressHUDFromTop()
            switch result {
            case .success(let channel):
                if let channel = channel,let _ = channel.user {
                    SendBirdChannel.sharedInstance = channel
                    self?.openChatView(on: currentController, channel: channel)
                }
                break
            case .failure(let reason):
                print(reason)
                break
            }
        }
        
        
//        ChatViewModel().fetchSendBirdUser(chatNotification.channelId) { (status, chatuser, error) in
//            if status && chatuser?.user != nil {
//                if MessageCenter.isConnected == false {
//                    self.connect((chatuser?.user)!, clientType: .sendBird, completion: { (success) in
//                        if success {
//                            if currentController != nil {
//                                self.openChatView(on: currentController!, chatUrl: (chatuser?.url)!, title: (chatuser?.title)!, subtitle: (chatuser?.subtitle)!, welcomeMessage: (chatuser?.welcome_message)!)
//                            }
//                        }
//                    })
//                }
//                else {
//                    if currentController != nil {
//                        self.openChatView(on: currentController!, chatUrl: (chatuser?.url)!, title: (chatuser?.title)!, subtitle: (chatuser?.subtitle)!, welcomeMessage: (chatuser?.welcome_message)!)
//                    }
//                }
//            }
//            else {
//
//            }
//        }

    }
    
    func refreshTabBarBadge () {
        self.unReadMessagesCount(chatUrl: nil, completion: { (count) in
            self.setOrdersChatBadgeCount(count: count)
        })
    }
    
    func setOrdersChatBadgeCount (count: Int) {
        
    }
    
    func dummy (_ vc: UIViewController) {
        
//        let connectionRequest = ConnectionRequest(appId: "FE3AD311-7F0F-4E7E-9E22-25FF141A37C0", userId: "rider_sony", accessToken: "4a8f3c197450b4762cd2dcf02a130816a503f4f2", client: .sendBird)
//        
//        MessageCenter.connect(connectionRequest, pushToken: "2121212324rdfdcef".data(using: .utf8), success: { (userId) in
//            
//            // Title for navigation bar
//            let title = "Rider name"
//            
//            // Subtitle to be displayed below title on navigation bar
//            let subtitle = "#12345678 • Restaurant"
//            
//            // Welcome Message
//            let welcomeMessage = "Hungerstation rider is here to serve you!"
//            
//            // Sender bubble color
//            let primaryColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 214.0/255.0, alpha: 1.0)
//            
//            // Color for Title, welcome message background (with alpha 0.4) and Send button background
//            let primaryAccentColor = UIColor(red: 245.0/255.0, green: 206.0/255.0, blue: 9.0/255.0, alpha: 1.0)
//            
//            // Back button color
//            let primaryNavigationIconColor = UIColor(red: 245.0/255.0, green: 200.0/255.0, blue: 0.0/255.0, alpha: 1.0)
//            
//            // Chat background color
//            let primaryBackgroundColor = UIColor(red: 244.0/255.0, green: 242.0/255.0, blue: 230.0/255.0, alpha: 1.0)
//            
//            // Action sheet icons, subtitles, and send button color
//            let primaryActionIconsColor = UIColor(red: 82.0/255.0, green: 67.0/255.0, blue: 62.0/255.0, alpha: 1.0)
//            
//            let theme = MessageCenter.createThemeObject(title: title,
//                                                        subtitle: subtitle,
//                                                        welcomeMessage: welcomeMessage,
//                                                        primaryColor: primaryColor,
//                                                        primaryAccentColor: primaryAccentColor,
//                                                        primaryNavigationButtonColor: primaryNavigationIconColor,
//                                                        primaryBackgroundColor: primaryBackgroundColor,
//                                                        primaryActionIconsColor: primaryActionIconsColor)
//            MessageCenter.parentVC = vc
//            IQKeyboardManager.shared.enable = false
//            IQKeyboardManager.shared.enableAutoToolbar = false
//            MessageCenter.openChatView("sendbird_group_channel_2456028_72db325775728aa550b52e11990d891167ed5f1f", theme: theme, completion: { (status) in
//                print(status)
//            })
//        }) { (errorCode, message) in
//            print("Error occured: %d %@", errorCode, message)
//        }
    }
}

