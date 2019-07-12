//
//  OutgoingUserMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/7/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK


class OutgoingUserMessageTableViewCell: OutgoingBaseCell {

    @IBOutlet weak var messageLabel: UILabel!

    
    static func nib() -> UINib {
        let podBundle = Bundle.bundleForXib(OutgoingUserMessageTableViewCell.self)
        return UINib(nibName: String(describing: self), bundle: podBundle)
    }
    
    func setModel(aMessage: SBDUserMessage, channel: SBDBaseChannel?) {
        
        self.textMessage = aMessage
        let fullMessage = self.buildMessage()
        
        self.messageLabel.attributedText = fullMessage
        
        self.resendMessageButton.isHidden = true
        

        // Message Status
        if self.textMessage.channelType == CHANNEL_TYPE_GROUP {
            if self.textMessage.messageId == 0 {
                self.imgMessageStatus.image = UIImage(named: "icMsgsent",in: Bundle.bundleForXib(OutgoingUserMessageTableViewCell.self), compatibleWith: nil)
            }
            else {
                if let messageChannel = channel as? SBDGroupChannel {
                    let unreadMessageCount = messageChannel.getReadReceipt(of: self.textMessage)
                    if unreadMessageCount == 0 {
                        // 0 means everybody has read the message
                        self.imgMessageStatus.image = UIImage(named: "icMsgread", in: Bundle.bundleForXib(OutgoingUserMessageTableViewCell.self), compatibleWith: nil)
                    }
                    else {
                        self.imgMessageStatus.image = UIImage(named: "icMsgdelivered", in: Bundle.bundleForXib(OutgoingUserMessageTableViewCell.self), compatibleWith: nil)

                    }
                }
            }
        }
        else {
            self.hideMessageStatus()
        }
        
        let messageTimestamp = Double(self.textMessage.createdAt) / 1000.0
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.locale = Locale(identifier: "en_US")
        let messageCreatedDate = NSDate(timeIntervalSince1970: messageTimestamp)
        let messageDateString = dateFormatter.string(from: messageCreatedDate as Date)
        self.messageDateLabel.text = messageDateString
        self.imgMessageStatus.contentMode = .scaleAspectFit
        self.layoutIfNeeded()
    }

    
    func buildMessage() -> NSAttributedString {
        
        let messageAttribute = [
            NSAttributedString.Key.font: Constants.messageFont,
            NSAttributedString.Key.foregroundColor: Constants.outgoingMessageColor,
        ]
        
        let message = self.textMessage.message
        let messageLength = message?.count ?? 0
        let fullMessage = NSMutableAttributedString(string: message!)
        fullMessage.addAttributes(messageAttribute, range: NSMakeRange(0, messageLength))
        
        return fullMessage
    }
    
}
