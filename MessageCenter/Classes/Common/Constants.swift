//
//  Constants.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/17/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit

public enum ClientType: String {
    case sendBird = "sendbird"
    case other = "other"
}

struct Constants {
    
    
    static let navigationBarTitleColor = UIColor(red: 245.0/255.0, green: 206.0/255.0, blue: 9.0/255.0, alpha: 1.0)
    static let navigationBarSubTitleColor =  UIColor(red: 82.0/255.0, green: 67.0/255.0, blue: 62.0/255.0, alpha: 1.0)
    
    static let navigationBarTitleFont = UIFont(name: "HelveticaNeue", size: 17.0)
    static let navigationBarSubTitleFont = UIFont(name: "HelveticaNeue-LightItalic", size: 17.0)
    static let nicknameFontInMessage = UIFont(name: "HelveticaNeue", size: 12.0)
    
    static let textFieldLineColorNormal =  UIColor(red: 217.0/255.0, green: 217.0/255.0, blue: 217.0/255.0, alpha: 1)
    static let textFieldLineColorSelected = UIColor(red: 140.0/255.0, green: 109.0/255.0, blue: 238.0/255.0, alpha: 1)
    
    static let messageDateFont = UIFont(name: "HelveticaNeue", size: 10.0)!
    static let messageDateColor = UIColor(red: 191.0/255.0, green: 191.0/255.0, blue: 191.0/255.0, alpha: 1)
    static let incomingFileImagePlaceholderColor = UIColor(red: 238.0/255.0, green: 241.0/255.0, blue: 246.0/255.0, alpha: 1)
    static let messageFont =  UIFont(name: "HelveticaNeue", size: 16.0)!
    static let outgoingMessageColor = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1)
    static let incomingMessageColor = UIColor(red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1)
    static let outgoingFileImagePlaceholderColor = UIColor(red: 128.0/255.0, green: 90.0/255.0, blue: 255.0/255.0, alpha: 1)
    static let leaveButtonColor = UIColor.red
    static let hideButtonColor =  UIColor(red: 116.0/255.0, green: 127.0/255.0, blue: 145.0/255.0, alpha: 1)
    static let leaveButtonFont = UIFont(name: "HelveticaNeue", size: 16.0)
    static let hideButtonFont = UIFont(name: "HelveticaNeue", size: 16.0)
    static let distinctButtonSelected = UIFont(name: "HelveticaNeue-Medium", size: 18.0)
    static let distinctButtonNormal = UIFont(name: "HelveticaNeue", size: 18.0)
    static let navigationBarButtonItemFont = UIFont(name: "HelveticaNeue", size: 16.0)
    static let urlPreviewDescriptionFont = UIFont(name: "HelveticaNeue-Light", size: 12.0)
    static let incommingCellBackgroungColor = UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0)
    
    static func defaultTheme () -> ThemeObject {
        let title = ""
        // Subtitle to be displayed below title on navigation bar
        let subtitle = ""
        // Welcome Message
        let welcomeMessage = ""
        // Sender bubble color
        let primaryColor = UIColor(red: 255.0/255.0, green: 247.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        // Color for Title, welcome message background (with alpha 0.4) and Send button background
        let primaryAccentColor = UIColor(red: 245.0/255.0, green: 206.0/255.0, blue: 9.0/255.0, alpha: 1.0)
        // Back button color
        let primaryNavigationIconColor = UIColor(red: 255.0/255.0, green: 200.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        // Chat background color
        let primaryBackgroundColor = UIColor(red: 244.0/255.0, green: 242.0/255.0, blue: 230.0/255.0, alpha: 1.0)
        // Action sheet icons, subtitles, and send button color
        let primaryActionIconsColor = UIColor(red: 82.0/255.0, green: 67.0/255.0, blue: 62.0/255.0, alpha: 1.0)
        
        return ThemeObject(title: title,
                    subtitle: subtitle,
                    welcomeMessage: welcomeMessage,
                    primaryColor: primaryColor,
                    primaryAccentColor: primaryAccentColor,
                    primaryButtonColor: primaryNavigationIconColor,
                    primaryBackgroundColor: primaryBackgroundColor,
                    primaryActionIconsColor: primaryActionIconsColor,
                    primaryNavigationButtonColor: primaryNavigationIconColor,
                    enableCalling: false)
    }
    
}
