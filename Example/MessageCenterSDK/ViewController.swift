//
//  ViewController.swift
//  FrameworkTest
//
//  Created by Ikarma Khan on 29/05/2019.
//  Copyright © 2019 Ikarma Khan. All rights reserved.
//

import UIKit
import MessageCenterSDK

class ViewController: UIViewController {
    
    private var theme : ThemeObject?
    
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
        
        theme = MessageCenter.createThemeObject(title: "title",
                                                subtitle: "subtitle",
                                                welcomeMessage: "welcomeMessage",
                                                primaryColor: primaryColor,
                                                primaryAccentColor: primaryAccentColor,
                                                primaryNavigationButtonColor: primaryNavigationIconColor,
                                                primaryBackgroundColor: primaryBackgroundColor,
                                                primaryActionIconsColor: primaryActionIconsColor)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.createTheme("", subtitle: "", welcomeMessage: "")
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appId = "FE3AD311-7F0F-4E7E-9E22-25FF141A37C0"
        let userId = "rider_barsi_m"
        let accessToken = "9ac31b1d6829634409c5fd5b0909f4b3107e1b29"
        let client = ClientType.sendBird
        let pushToken = "2121212324rdfdcef".data(using: .utf8)
        let unique = false
        let channel = "sendbird_group_channel_3200992_1fbbfcf89d9537d4c8f9aafbe280abc4719837d2"
        let channelId = "sendbird_group_channel_3200992_1fbbfcf89d9537d4c8f9aafbe280abc4719837d2"
        
        let connectionRequest = ConnectionRequest(appId: appId, userId: userId, accessToken: accessToken, client: client, unique: unique)
        connectionRequest.updateChannelId(channelId: channelId)
        connectionRequest.updateChannel(channel: channel)
        connectionRequest.updatePushToken(pushToken: pushToken)
        
        MessageCenter.setParentVC(vc: self)
        
        MessageCenter.registerUserToken(connectionRequest: connectionRequest) { (status) in
            
            // Registered
            if status {
                MessageCenter.openChatView(connectionRequest: connectionRequest, theme: self.theme, success: { (yo) in
                    
                }, failure: { (code, message) in
                    
                })
            }
            else {
                
            }
            
        }
        
        
    }
    
}

