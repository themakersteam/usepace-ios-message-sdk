//
//  OutgoingImageFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/7/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import FLAnimatedImage
import SendBirdSDK

class OutgoingImageFileMessageTableViewCell: OutgoingBaseCell {
    
    
    var fileMessage : SBDFileMessage! {
        didSet {
            loadImage()
        }
    }
    
    @IBOutlet weak var fileImageView: FLAnimatedImageView!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    
    public var hasImageCacheData: Bool?
    
    static func nib() -> UINib {        
        let podBundle = Bundle.bundleForXib(OutgoingImageFileMessageTableViewCell.self)
        return UINib(nibName: String(describing: self), bundle: podBundle)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fileImageView.image = nil
        fileImageView.animatedImage = nil
        fileImageView.layer.cornerRadius = 8.0
    }
    
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    
    @objc private func clickFileMessage() {
        self.delegate?.clickMessage(view: self, message: message!)
    }
    
    func setModel(aMessage: SBDFileMessage, channel: SBDBaseChannel?) {
        
        fileImageView.image = nil
        fileImageView.animatedImage = nil
        
        self.message = aMessage
        
        if self.hasImageCacheData == false {
            self.imageLoadingIndicator.isHidden = false
            self.imageLoadingIndicator.startAnimating()
        }
        else {
            self.imageLoadingIndicator.isHidden = true
            self.imageLoadingIndicator.stopAnimating()
        }
        
        self.fileImageView.animatedImage = nil
        self.fileImageView.image = nil

    
        let messageContainerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickFileMessage))
        self.fileImageView.isUserInteractionEnabled = true
        self.fileImageView.addGestureRecognizer(messageContainerTapRecognizer)
        
        // Message Status
        if self.message.channelType == CHANNEL_TYPE_GROUP {
            if self.message.messageId == 0 {
                self.imgMessageStatus.image = UIImage(named: "icMsgsent", in: Bundle.bundleForXib(OutgoingImageFileMessageTableViewCell.self), compatibleWith: nil)
            }
            else {
                if let channelOfMessage = channel as? SBDGroupChannel? {
                    let unreadMessageCount = channelOfMessage?.getReadReceipt(of: self.message)
                    if unreadMessageCount == 0 {
                        // 0 means everybody has read the message
                        self.imgMessageStatus.image = UIImage(named: "icMsgread", in: Bundle.bundleForXib(OutgoingImageFileMessageTableViewCell.self), compatibleWith: nil)
                    }
                    else {
                        self.imgMessageStatus.image = UIImage(named: "icMsgdelivered", in: Bundle.bundleForXib(OutgoingImageFileMessageTableViewCell.self), compatibleWith: nil)
                        
                    }
                }
            }
        }
        else {
            self.hideMessageStatus()
        }
        
        // Message Date
        let messageDateAttribute = [
            NSAttributedString.Key.font: Constants.messageDateFont,
            NSAttributedString.Key.foregroundColor: Constants.messageDateColor
        ]
        
        let messageTimestamp = Double(self.message.createdAt) / 1000.0
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.locale = Locale(identifier: "en_US")
        let messageCreatedDate = NSDate(timeIntervalSince1970: messageTimestamp)
        let messageDateString = dateFormatter.string(from: messageCreatedDate as Date)
        
        let messageDateAttributedString = NSMutableAttributedString(string: messageDateString, attributes: messageDateAttribute)
        self.messageDateLabel.attributedText = messageDateAttributedString
        self.imgMessageStatus.contentMode = .scaleAspectFit
        self.layoutIfNeeded()
    }
    
    
    
    func updateBackgroundColour () {
        self.messageContainerView.backgroundColor = self.containerBackgroundColour
    }
    
    func getHeightOfViewCell() -> CGFloat {
        return 210.0
    }
    
    
    override func showSendingStatus() {
        super.showSendingStatus()
        self.imageLoadingIndicator.startAnimating()
        self.imageLoadingIndicator.isHidden = false
    }
    
   override func showFailedStatus() {
        super.showFailedStatus()
        self.imageLoadingIndicator.stopAnimating()
        self.imageLoadingIndicator.isHidden = true
    }
    
    
    override func showMessageStatus() {
        super.showMessageStatus()
        self.imageLoadingIndicator.stopAnimating()
        self.imageLoadingIndicator.isHidden = true
    }
    
    override func updateOnPreSendMessage () {
        super.updateOnPreSendMessage()
        hasImageCacheData = true
        
        if self.message != nil {
          //setImageData(data: self.preSendFileData[fileMessage.requestId!]!["data"] as! Data, type: self.preSendFileData[fileMessage.requestId!]!["type"] as! String)
        }
        //
    }
    
    func loadImage () {
        
        var fileImageUrl = ""
        
        
        if let thumbnails = fileMessage.thumbnails {
            let thumbnailsCount = thumbnails.count
            if thumbnailsCount > 0 && fileMessage.type != "image/gif" {
                fileImageUrl = thumbnails[0].url
            }
            else {
                fileImageUrl = fileMessage.url
            }
        }
        
        fileImageView.image = nil
        fileImageView.animatedImage = nil
        
        guard let url = URL(string: fileImageUrl) else {
            return
        }
        self.imageLoadingIndicator.startAnimating()
        self.imageLoadingIndicator.isHidden = false

        if fileMessage.type == "image/gif" {
            fileImageView.setAnimatedImageWithURL(url: url, success: { (image) in
                DispatchQueue.main.async { [weak self] in
                    self?.fileImageView.animatedImage = image
                    self?.imageLoadingIndicator.stopAnimating()
                    self?.imageLoadingIndicator.isHidden = true
                }
                
            }, failure: { (error) in
                DispatchQueue.main.async { [weak self] in
                    self?.fileImageView.af_setImage(withURL: url)
                    self?.imageLoadingIndicator.stopAnimating()
                    self?.imageLoadingIndicator.isHidden = true
                }
            })
        }
        else {
            let request = URLRequest(url: url)
            
            fileImageView.af_setImage(withURLRequest: request,
                                      placeholderImage: nil,
                                      imageTransition: UIImageView.ImageTransition.noTransition,
                                      completion: { (response) in
                                        
                if response.result.error != nil {
                    DispatchQueue.main.async { [weak self] in
                        self?.fileImageView.image = nil
                        self?.imageLoadingIndicator.isHidden = true
                        self?.imageLoadingIndicator.stopAnimating()
                    }
                }
                else {
                    DispatchQueue.main.async { [weak self] in
                        self?.fileImageView.image = response.result.value
                        self?.imageLoadingIndicator.isHidden = true
                        self?.imageLoadingIndicator.stopAnimating()
                        
                    }
                }
            })
        }
    }
    
    func setImageData(data: Data, type: String) {
        
        
        fileImageView.animatedImage = nil
        
        if self.hasImageCacheData == true {
            self.imageLoadingIndicator.isHidden = true
            self.imageLoadingIndicator.stopAnimating()
        }
        
        if type == "image/gif" {
            let imageLoadQueue = DispatchQueue(label: "com.sendbird.imageloadqueue");
            imageLoadQueue.async {
                let animatedImage = FLAnimatedImage(animatedGIFData: data)
                DispatchQueue.main.async {
                    self.fileImageView.animatedImage = animatedImage;
                }
            }
        }
        else {
            fileImageView.image = nil
            self.fileImageView.image = UIImage(data: data)
            
        }
        
        
    }
}
