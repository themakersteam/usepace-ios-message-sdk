//
//  OutgoingBaseCell.swift
//  MessageCenter
//
//  Created by Ikarma Khan on 17/06/2019.
//  Copyright © 2019 Ikarma Khan. All rights reserved.
//

import Foundation

import SendBirdSDK

class OutgoingBaseCell : UITableViewCell {
    
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var imgMessageStatus: UIImageView!
    @IBOutlet weak var resendMessageButton: UIButton!
    @IBOutlet weak var statusTimeStampTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var resendButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cnMessageContainerLeftPadding: NSLayoutConstraint!
    @IBOutlet weak var vwTimestampStatus: UIView!
    
    var containerBackgroundColour: UIColor = UIColor(red: 122.0/255.0, green: 188.0/255.0, blue: 65.0/255.0, alpha: 1.0)
    
    var message: SBDFileMessage!
    var textMessage: SBDUserMessage!
    var prevMessage: SBDBaseMessage?
    var preSendMessage : SBDBaseMessage! {
        didSet {
            updateOnPreSendMessage()
        }
    }
    
    var themeObject : ThemeObject! {
        didSet {
            updateTheme()
        }
    }
    
    weak var delegate: MessageDelegate?
    
    override func awakeFromNib() {
        
        messageContainerView.layer.cornerRadius = 8.0
        messageDateLabel.font = UIFont.systemFont(ofSize: 10)
        resendMessageButton.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        
        resendMessageButton.setTitle("ms_chat_failed_to_send".localized, for: .normal)
        
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            resendMessageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
            
            if resendButtonWidthConstraint != nil {
                resendButtonWidthConstraint.constant = 88
            }
        }
        else {
            resendMessageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
            if statusTimeStampTrailingConstraint != nil {
                statusTimeStampTrailingConstraint.constant = 10
            }
            if resendButtonWidthConstraint != nil {
                resendButtonWidthConstraint.constant = 110
            }
            if vwTimestampStatus != nil {
                vwTimestampStatus.layoutIfNeeded()
            }
            
        }
        self.backgroundColor = .clear
        resendMessageButton.addTarget(self, action: #selector(clickResendUserMessage), for: UIControl.Event.touchUpInside)
//        self.resendMessageButton.layoutIfNeeded()
    }
    
    func hideMessageResendButton() {
        resendMessageButton.isHidden = true
    }
    
    func showMessageResendButton() {
        
        messageDateLabel.isHidden = true
        imgMessageStatus.isHidden = true
        resendMessageButton.isHidden = false
    }
    
    func showSendingStatus() {
        messageDateLabel.isHidden = false
        imgMessageStatus.isHidden = false
        resendMessageButton.isHidden = true
    }
    
    func showFailedStatus() {
        messageDateLabel.isHidden = true
        imgMessageStatus.isHidden = true
        resendMessageButton.isHidden = false
    }
    
    func hideMessageStatus () {
        messageDateLabel.isHidden = true
        imgMessageStatus.isHidden = true
    }
    
    func showMessageStatus() {
        imgMessageStatus.isHidden = false
        messageDateLabel.isHidden = false
        resendMessageButton.isHidden = true
    }
    
    func setPreviousMessage(aPrevMessage: SBDBaseMessage?) {
        prevMessage = aPrevMessage
    }
    
    func updateOnPreSendMessage () {
        showSendingStatus()
    }
    
    func updateTheme() {
        if let primaryColor = themeObject.primaryColor {
            containerBackgroundColour = primaryColor
            messageContainerView.backgroundColor = primaryColor
        }
    }
    
    @objc private func clickResendUserMessage() {
        
        if textMessage != nil {
            self.delegate?.clickResend(view: self, message: self.textMessage!)
            return
        }
        if message != nil {
            self.delegate?.clickResend(view: self, message: self.message!)
        }
        
        
    }
    
    @objc private func clickUserMessage() {
        
        if textMessage != nil {
            self.delegate?.clickMessage(view: self, message: self.textMessage!)
            return
        }
        if message != nil {
            self.delegate?.clickMessage(view: self, message: self.message!)
        }
    }
    
    @objc private func clickDeleteUserMessage() {
        if textMessage != nil {
            self.delegate?.clickDelete(view: self, message: self.textMessage)
            return
        }
        if message != nil {
            self.delegate?.clickDelete(view: self, message: self.message!)
        }
    }
}
