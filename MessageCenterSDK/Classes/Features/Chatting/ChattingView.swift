//
//  ChattingView.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/7/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import Alamofire



protocol ChattingViewDelegate: class {
    func loadMoreMessage(view: UIView)
    func startTyping(view: UIView)
    func endTyping(view: UIView)
    func hideKeyboardWhenFastScrolling(view: UIView)
}

class ChattingView: ReusableViewFromXib, UITableViewDelegate, UITableViewDataSource {
    // MARK : - IBOutlets
    @IBOutlet weak var messageTextView: SBMessageInputView!
    @IBOutlet weak var chattingTableView: UITableView!
    @IBOutlet weak var inputContainerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var cnTextViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var typingIndicatorImageHeight: NSLayoutConstraint!
    @IBOutlet weak var typingIndicatorContainerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var typingIndicatorImageView: UIImageView!
    @IBOutlet weak var typingIndicatorLabel: UILabel!
    @IBOutlet weak var typingIndicatorContainerView: UIView!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var inputContainerViewBackground: UIView!
    @IBOutlet weak var fileAttachButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var btnCamera: UIButton!
    
    @IBOutlet weak var chattingTableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chattingTableViewBottomToSafeAreConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var attachButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachButtonTrailingConstraint: NSLayoutConstraint!
    
    // MARK: - Vars
    
    var stopMeasuringVelocity: Bool = true
    var initialLoading: Bool = true
    var resendableFileData: [String:[String:AnyObject]] = [:]
    var preSendFileData: [String:[String:AnyObject]] = [:]
    var messages: [SBDBaseMessage] = []
    //var hasLoadedAllMessages: Bool = false
    var channel: SBDBaseChannel?
    var themeObject: ThemeObject?
    private var podBundle: Bundle!
    
    var welcomeMessage: String = ""
    
    var resendableMessages: [String:SBDBaseMessage] = [:]
    var preSendMessages: [String:SBDBaseMessage] = [:]
    
    weak var delegate: (ChattingViewDelegate & MessageDelegate)?
    
    var lastMessageHeight: CGFloat = 0
    var scrollLock: Bool = false
    
    var lastOffset: CGPoint = CGPoint(x: 0, y: 0)
    var lastOffsetCapture: TimeInterval = 0
    var isScrollingFast: Bool = false
    
    private var _currentUserId: String = ""
   
    var currentUserId: String {
        get {
            if self._currentUserId != "" {
                return self._currentUserId
            }
            return SBDMain.getCurrentUser()?.userId ?? ""
        }
        set {
            self._currentUserId = newValue
        }
    }
    private var previousLine : Int = 0
    
    // MARK: - viewLifeCycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        self.podBundle = Bundle.bundleForXib(ChattingView.self)
        self.setup()
    }
    
    // MARK: - Helpers
    func setup() {
        self.chattingTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        self.placeholderLabel.text = "type_message_hint".localized
        
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            attachButtonTrailingConstraint.constant = 22
            attachButtonLeadingConstraint.constant = 0
            fileAttachButton.layoutIfNeeded()
        }
    }
    
    func updateTheme(themeObject: ThemeObject) {
        self.themeObject = themeObject
        fileAttachButton.tintColor = themeObject.primaryActionIconsColor
        btnCamera.tintColor = themeObject.primaryActionIconsColor
        sendButton.backgroundColor = themeObject.primaryAccentColor
        sendButton.imageView?.tintColor = themeObject.primaryActionIconsColor
        sendButton.layer.cornerRadius = 22.0
        self.sendButton.imageView?.tintColor = self.themeObject?.primaryColor!
    }
    
    // MARK: - configureChatView
    
    func configureChattingView(channel: SBDBaseChannel?) {
        
        if let channel = channel {
            self.channel = channel
            
            // Check if channel is frozen to hide the Text Sending view
            
            self.inputContainerView.isHidden = channel.isFrozen
            self.inputContainerViewBackground.isHidden = channel.isFrozen
            
            if channel.isFrozen {
                self.chattingTableViewBottomConstraint.priority = UILayoutPriority(900)
                self.chattingTableViewBottomToSafeAreConstraint.priority = UILayoutPriority(990)
            }
            else {
                self.chattingTableViewBottomConstraint.priority = UILayoutPriority(990)
                self.chattingTableViewBottomToSafeAreConstraint.priority = UILayoutPriority(900)
            }
        }
        
        // Workaround: Attach button in Arabic Layout is shifting to the right
        if UIView.userInterfaceLayoutDirection(for: UIView.appearance().semanticContentAttribute) == .rightToLeft {
            fileAttachButton.imageEdgeInsets.left = -fileAttachButton.frame.width
        }
        
        
        self.initialLoading = true
        self.lastMessageHeight = 0
        self.scrollLock = false
        self.stopMeasuringVelocity = false
        
        self.typingIndicatorContainerView.isHidden = true
        self.typingIndicatorContainerViewHeight.constant = 0
        self.typingIndicatorImageHeight.constant = 0
        
        messageTextView.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.12).cgColor
        self.messageTextView.layer.cornerRadius = 8.0
        self.messageTextView.layer.masksToBounds = true
        self.messageTextView.layer.borderWidth = 1.0
        self.messageTextView.delegate = self
     
        configureTableView()
    }
    
    
    private func configureTableView () {
        
        self.chattingTableView.register(NeutralMessageTableViewCell.nib(), forCellReuseIdentifier: NeutralMessageTableViewCell.string)
        
        // Header
        self.chattingTableView.register(WelcomeMessageTableViewCell.nib(), forCellReuseIdentifier: WelcomeMessageTableViewCell.string)
        
        // Incomming
        self.chattingTableView.register(IncomingUserMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingUserMessageTableViewCell.string)
        self.chattingTableView.register(IncomingImageFileMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingImageFileMessageTableViewCell.string)
        self.chattingTableView.register(IncomingGeneralUrlPreviewMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingGeneralUrlPreviewMessageTableViewCell.string)
        self.chattingTableView.register(IncomingLocationMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingLocationMessageTableViewCell.string)

        // Outgoing
        self.chattingTableView.register(OutgoingUserMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingUserMessageTableViewCell.string)
        self.chattingTableView.register(OutgoingImageFileMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingImageFileMessageTableViewCell.string)
        self.chattingTableView.register(OutgoingGeneralUrlPreviewMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingGeneralUrlPreviewMessageTableViewCell.string)
        self.chattingTableView.register(OutgoingGeneralUrlPreviewTempMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingGeneralUrlPreviewTempMessageTableViewCell.string)
        self.chattingTableView.register(OutgoingLocationMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingLocationMessageTableViewCell.string)
        
        self.chattingTableView.delegate = self
        self.chattingTableView.dataSource = self
    }
    
    // MARK: - scrollHandler
    
    func scrollToBottom(force: Bool) {
        if self.messages.count == 0 {
            return
        }
        
        if self.scrollLock == true && force == false {
            return
        }
        
        //   Find number of sections, rows in that section and scroll.
        let section = chattingTableView.numberOfSections - 1

        if section < 0 {
            return
        }
        
        let rows = chattingTableView.numberOfRows(inSection: section) - 1

        if rows < 0 {
            return
        }
        
        let indexPath = IndexPath(row: rows, section: section)
        self.chattingTableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
        self.chattingTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)        
    }
    
    // MARK: - typingIndicatorHandlers
    
    func startTypingIndicator(text: String) {
        // Typing indicator
        self.typingIndicatorContainerView.isHidden = false
        self.typingIndicatorLabel.text = text
        
        self.typingIndicatorContainerViewHeight.constant = 26.0
        self.typingIndicatorImageHeight.constant = 26.0
        self.typingIndicatorContainerView.layoutIfNeeded()
        
        if self.typingIndicatorImageView.isAnimating == false {
            var typingImages: [UIImage] = []
            for i in 1...50 {
                let typingImageFrameName = String.init(format: "%02d", i)
                typingImages.append(UIImage(named: typingImageFrameName, in: podBundle, compatibleWith: nil)!)
            }
            self.typingIndicatorImageView.animationImages = typingImages
            self.typingIndicatorImageView.animationDuration = 1.5
            
            DispatchQueue.main.async {
                self.typingIndicatorImageView.startAnimating()
            }
        }
    }
    
    func endTypingIndicator() {
        DispatchQueue.main.async {
            self.typingIndicatorImageView.stopAnimating()
        }
        
        self.typingIndicatorContainerView.isHidden = true
        self.typingIndicatorContainerViewHeight.constant = 0
        self.typingIndicatorImageHeight.constant = 0
        
        self.typingIndicatorContainerView.layoutIfNeeded()
    }
    
   
    
    
    // MARK: - scrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        self.stopMeasuringVelocity = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        self.stopMeasuringVelocity = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.chattingTableView {
            if self.stopMeasuringVelocity == false {
                let currentOffset = scrollView.contentOffset
                let currentTime = NSDate.timeIntervalSinceReferenceDate
                
                let timeDiff = currentTime - self.lastOffsetCapture
                if timeDiff > 0.1 {
                    let distance = currentOffset.y - self.lastOffset.y
                    let scrollSpeedNotAbs = distance * 10 / 1000
                    let scrollSpeed = abs(scrollSpeedNotAbs)
                    if scrollSpeed > 0.5 {
                        self.isScrollingFast = true
                    }
                    else {
                        self.isScrollingFast = false
                    }
                    
                    self.lastOffset = currentOffset
                    self.lastOffsetCapture = currentTime
                }
                
                if self.isScrollingFast {
                    if self.delegate != nil {
                        self.delegate?.hideKeyboardWhenFastScrolling(view: self)
                    }
                }
            }
            
            if scrollView.contentOffset.y + scrollView.frame.size.height + self.lastMessageHeight < scrollView.contentSize.height {
                self.scrollLock = true
            }
            else {
                self.scrollLock = false
            }
            
            if scrollView.contentOffset.y == 0 {
                if self.messages.count > 0 && self.initialLoading == false {
                    if self.delegate != nil {
                        self.delegate?.loadMoreMessage(view: self)
                    }
                }
            }
        }
    }
    // MARK: - TableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.scrollToNearestSelectedRow(at: .bottom, animated: false)
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    // MARK: -  UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return section == 0 ? 1 : self.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: WelcomeMessageTableViewCell.string, for: indexPath) as? WelcomeMessageTableViewCell {
                cell.themeObject = themeObject
                return cell
            }
        }
        
        let prevMessage = (indexPath.row > 0 && messages.count < indexPath.row - 1) ? messages[indexPath.row] : nil
        
        let msg = self.messages[indexPath.row] //(self.hasLoadedAllMessages == true ? 1 : 0)]
        
        if msg is SBDUserMessage {
            let userMessage = msg as! SBDUserMessage
            let sender = userMessage.sender
            
            if sender?.userId == currentUserId {
                // Outgoing
                if userMessage.customType == "url_preview" {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: OutgoingGeneralUrlPreviewMessageTableViewCell.string, for: indexPath) as? OutgoingGeneralUrlPreviewMessageTableViewCell else {
                        // FIXME: --- 
                        return UITableViewCell()
                    }
                    
                    if themeObject != nil {
                        if themeObject?.primaryColor != nil {
                            cell.containerBackgroundColour = (themeObject?.primaryColor)!
                        }
                    }
                    
                    cell.updateBackgroundColour()
                    
                   // cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row])
                    }
                    else {
                        cell.setPreviousMessage(aPrevMessage: nil)
                    }
                    cell.setModel(aMessage: userMessage, channel: self.channel)
                    cell.delegate = self.delegate
                    
                    if let imageUrl = cell.previewData["image"] as? String {
                        let ext = (imageUrl as NSString).pathExtension
                        
                        cell.previewThumbnailImageView.image = nil
                        cell.previewThumbnailImageView.animatedImage = nil
                        cell.previewThumbnailLoadingIndicator.isHidden = false
                        cell.previewThumbnailLoadingIndicator.startAnimating()
                        
                        if !imageUrl.isEmpty {
                            if ext.lowercased().hasPrefix("gif") {
                                cell.previewThumbnailImageView.setAnimatedImageWithURL(url: URL(string: imageUrl)! , success: { (image) in
                                    DispatchQueue.main.async {
                                        cell.previewThumbnailImageView.animatedImage = image
                                        cell.previewThumbnailLoadingIndicator.isHidden = true
                                        cell.previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                }, failure: { (error) in
                                    DispatchQueue.main.async {
                                        cell.previewThumbnailLoadingIndicator.isHidden = true
                                        cell.previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                })
                            }
                            else {

                                Alamofire.request(imageUrl, method: .get).responseImage { response in
                                    
                                    guard let image = response.result.value else {
                                        DispatchQueue.main.async {
                                            cell.previewThumbnailLoadingIndicator.isHidden = true
                                            cell.previewThumbnailLoadingIndicator.stopAnimating()
                                        }
                                        
                                        return
                                    }
                                    
                                    DispatchQueue.main.async {
                                        cell.previewThumbnailImageView.image = image
                                        cell.previewThumbnailLoadingIndicator.isHidden = true
                                        cell.previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                }
                            }
                        }
                        if self.preSendMessages[userMessage.requestId!] != nil {
                            cell.showSendingStatus()
                        }
                        else {
                            if self.resendableMessages[userMessage.requestId!] != nil {
                                cell.showMessageResendButton()
                                //                            cell.showFailedStatus()
                            }
                            else {
                                cell.showMessageStatus()
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            cell.previewThumbnailLoadingIndicator.isHidden = true
                            cell.previewThumbnailLoadingIndicator.stopAnimating()
                        }
                    }
                    
                    return cell
                }
                else if (userMessage.message?.contains("location://"))! {
                    cell = tableView.dequeueReusableCell(withIdentifier: OutgoingLocationMessageTableViewCell.string)
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! OutgoingLocationMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row])
                    }
                    else {
                        (cell as! OutgoingLocationMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! OutgoingLocationMessageTableViewCell).setModel(aMessage: userMessage, channel: self.channel)
                    (cell as! OutgoingLocationMessageTableViewCell).delegate = self.delegate
                    
                    if themeObject != nil {
                        if themeObject?.primaryColor != nil {
                            (cell as! OutgoingLocationMessageTableViewCell).containerBackgroundColour = (themeObject?.primaryColor)!
                        }
                    }
                    (cell as! OutgoingLocationMessageTableViewCell).updateBackgroundColour()
                    
                    if self.preSendMessages[userMessage.requestId!] != nil {
                        (cell as! OutgoingLocationMessageTableViewCell).showSendingStatus()
                    }
                    else {
                        if self.resendableMessages[userMessage.requestId!] != nil {
                            (cell as! OutgoingLocationMessageTableViewCell).showMessageResendButton()
                            (cell as! OutgoingLocationMessageTableViewCell).showFailedStatus()
                        }
                        else {
                            (cell as! OutgoingLocationMessageTableViewCell).showMessageStatus()
                        }
                    }
                    
                }
                else {
                    
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: OutgoingUserMessageTableViewCell.string, for: indexPath) as? OutgoingUserMessageTableViewCell else {
                        return UITableViewCell()
                    }
                    if indexPath.row > 0 {
                        cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row])
                    }
                    else {
                        cell.setPreviousMessage(aPrevMessage: nil)
                    }
                    cell.setModel(aMessage: userMessage, channel: self.channel)
                    cell.delegate = self.delegate
                    cell.themeObject = themeObject
                    
                    
                    if let requestId = userMessage.requestId {
                        if let _ = preSendMessages[requestId] {
                            cell.showSendingStatus()
                        }
                        
                        else {
                            if let _ = resendableMessages[requestId] {
                                cell.showMessageResendButton()
                                cell.showFailedStatus()
                            }
                            else {
                                cell.showMessageStatus()
                            }
                        }
                    }
                    // Outgoing TextMessage Cell
                    return cell
                }
            }
            else {
                // Incoming
                if userMessage.customType == "url_preview" {
                    cell = tableView.dequeueReusableCell(withIdentifier: IncomingGeneralUrlPreviewMessageTableViewCell.string)
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row])
                    }
                    else {
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).setModel(aMessage: userMessage)
                    (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).delegate = self.delegate
                    
                    var ext: String?
                    if let imageUrl = (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewData["image"] as? String {
                        ext = (imageUrl as NSString).pathExtension
                        
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.image = nil
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.animatedImage = nil
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = false
                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.startAnimating()
                        
                        if !imageUrl.isEmpty {
                            if ext!.lowercased().hasPrefix("gif") {
                                (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.setAnimatedImageWithURL(url: URL(string: imageUrl)! , success: { (image) in
                                    DispatchQueue.main.async {
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.image = nil
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.animatedImage = nil
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.animatedImage = image
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                }, failure: { (error) in
                                    DispatchQueue.main.async {
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                })
                            }
                            else {
                                Alamofire.request(imageUrl, method: .get).responseImage { response in
                                    
                                    guard let image = response.result.value else {
                                        DispatchQueue.main.async {
                                            (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                            (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                        }
                                        
                                        return
                                    }
                                    
                                    DispatchQueue.main.async {
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailImageView.image = image
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                                        (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                                    }
                                }
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.isHidden = true
                            (cell as! IncomingGeneralUrlPreviewMessageTableViewCell).previewThumbnailLoadingIndicator.stopAnimating()
                        }
                    }
                }
                else if (userMessage.message?.contains("location://"))! {
                    cell = tableView.dequeueReusableCell(withIdentifier: IncomingLocationMessageTableViewCell.string)
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! IncomingLocationMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row])
                    }
                    else {
                        (cell as! IncomingLocationMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! IncomingLocationMessageTableViewCell).setModel(aMessage: userMessage)
                    (cell as! IncomingLocationMessageTableViewCell).delegate = self.delegate
                }
                else {
                    cell = tableView.dequeueReusableCell(withIdentifier: IncomingUserMessageTableViewCell.string)
                    
                    cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
                    if indexPath.row > 0 {
                        (cell as! IncomingUserMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row])
                    }
                    else {
                        (cell as! IncomingUserMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
                    }
                    (cell as! IncomingUserMessageTableViewCell).setModel(aMessage: userMessage)
                    (cell as! IncomingUserMessageTableViewCell).delegate = self.delegate
                }
            }
            
        }
        else if msg is SBDFileMessage {
            let fileMessage = msg as! SBDFileMessage
            let sender = fileMessage.sender
            
            if sender?.userId == currentUserId {
                // Outgoing
                // MARK: - Outgoing - File Image
                if fileMessage.type.hasPrefix("image") {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: OutgoingImageFileMessageTableViewCell.string, for: indexPath) as? OutgoingImageFileMessageTableViewCell else {
                        return UITableViewCell()
                    }

                    cell.themeObject = themeObject
                    cell.setPreviousMessage(aPrevMessage: prevMessage)
                    cell.setModel(aMessage: fileMessage, channel: self.channel)
                    cell.delegate = self.delegate
                    if let requestId = fileMessage.requestId {
                        
                        if let image = CommonUtils.getImageFromDocumentDirectory(requestId) {
                            cell.fileImageView.image = image
                        }
                        else {
                            cell.fileImageView.image = nil
                        }

                        
                        cell.imageLoadingIndicator.startAnimating()
                        cell.imageLoadingIndicator.isHidden = false
                        
                        // Pre-Send Message - Message sending in progress
                        if let preSendMessage = preSendMessages[requestId] {
                            cell.preSendMessage = preSendMessage
                            if let fileData = preSendFileData[requestId] {
                                if let data = fileData["data"] as? Data , let type = fileData["type"] as? String {
                                    cell.setImageData(data: data, type: type)
                                    cell.hasImageCacheData = true
                                    cell.showSendingStatus()
                                    return cell
                                }
                            }
                        }
                        
                        else {
                            // Re-send Message - Message was failed
                            if let _ = resendableMessages[requestId],
                                let resendMessageData = resendableFileData[requestId],
                                let data = resendMessageData["data"] as? Data, let type = resendMessageData["type"] as? String {
                                
                                cell.setImageData(data: data, type: type)
                                cell.hasImageCacheData = true
                                cell.showMessageResendButton()
                                return cell
                            }
                            
                            else {
                                // Cached Message - already sent
                                
                                if !fileMessage.url.isEmpty , let fileData = preSendFileData[requestId] {
                                    if let data = fileData["data"] as? Data , let type = fileData["type"] as? String {
                                        cell.setImageData(data: data, type: type)
                                        cell.hasImageCacheData = true
                                        self.preSendFileData.removeValue(forKey: requestId)
                                        cell.showMessageStatus()
                                        return cell
                                    }
                                }
                                    // New Message/not-cached - to be loaded
                                else {
                                    
                                    cell.hasImageCacheData = false
                                    cell.fileMessage = fileMessage
                                    cell.showSendingStatus()                                }
                            }
                        }
                        
                        return cell
                        
//                        return cell
                    }
                }
                
            }
            else {
                // Incoming
                // here
                if fileMessage.type.hasPrefix("image") {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: IncomingImageFileMessageTableViewCell.string, for: indexPath) as? IncomingImageFileMessageTableViewCell else {
                        return UITableViewCell()
                    }
                    
                    cell.backgroundColor = cell.containerBackgroundColour
                    
                    if indexPath.row > 0 {
                        cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row])
                    }
                    else {
                        cell.setPreviousMessage(aPrevMessage: nil)
                    }
                    
                    cell.setModel(aMessage: fileMessage)
                    cell.delegate = self.delegate
                    
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
                    
                    cell.fileImageView.image = nil
                    cell.fileImageView.animatedImage = nil
                    
                    cell.imageLoadingIndicator.isHidden = false
                    cell.imageLoadingIndicator.startAnimating()
                    
                    if fileMessage.type == "image/gif" {
                        cell.fileImageView.setAnimatedImageWithURL(url: URL(string: fileImageUrl)!, success: { (image) in
                            DispatchQueue.main.async {
                                let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
                                if updateCell != nil {
                                    cell.fileImageView.animatedImage = image
                                    cell.imageLoadingIndicator.stopAnimating()
                                    cell.imageLoadingIndicator.isHidden = true
                                }
                            }
                        }, failure: { (error) in
                            DispatchQueue.main.async {
                                let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
                                if updateCell != nil {
                                    cell.fileImageView.af_setImage(withURL: URL(string: fileImageUrl)!)
                                    cell.imageLoadingIndicator.stopAnimating()
                                    cell.imageLoadingIndicator.isHidden = true
                                }
                            }
                        })
                    }
                    else {
                        let request = URLRequest(url: URL(string: fileImageUrl)!)
                        cell.fileImageView.af_setImage(withURLRequest: request, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
                            if response.result.error != nil {
                                DispatchQueue.main.async {
                                    let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
                                    if updateCell != nil {
                                        cell.fileImageView.image = nil
                                        cell.imageLoadingIndicator.isHidden = true
                                        cell.imageLoadingIndicator.stopAnimating()
                                    }
                                }
                            }
                            else {
                                DispatchQueue.main.async {
                                    let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
                                    if updateCell != nil {
                                        cell.fileImageView.image = response.result.value
                                        cell.imageLoadingIndicator.isHidden = true
                                        cell.imageLoadingIndicator.stopAnimating()
                                    }
                                }
                            }
                        })
                    }
                    cell.backgroundColor = .clear
                    return cell
                }
            }
        }
        else if msg is SBDAdminMessage {
            let adminMessage = msg as! SBDAdminMessage
            
            cell = tableView.dequeueReusableCell(withIdentifier: NeutralMessageTableViewCell.string)
            cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
            if indexPath.row > 0 {
                (cell as! NeutralMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row])
            }
            else {
                (cell as! NeutralMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
            }
            
            (cell as! NeutralMessageTableViewCell).setModel(aMessage: adminMessage)
        }
        else if msg is OutgoingGeneralUrlPreviewTempModel {
            let model = msg as! OutgoingGeneralUrlPreviewTempModel
            
            cell = tableView.dequeueReusableCell(withIdentifier: OutgoingGeneralUrlPreviewTempMessageTableViewCell.string)
            cell?.frame = CGRect(x: (cell?.frame.origin.x)!, y: (cell?.frame.origin.y)!, width: (cell?.frame.size.width)!, height: (cell?.frame.size.height)!)
            if indexPath.row > 0 {
                (cell as! OutgoingGeneralUrlPreviewTempMessageTableViewCell).setPreviousMessage(aPrevMessage: self.messages[indexPath.row])
            }
            else {
                (cell as! OutgoingGeneralUrlPreviewTempMessageTableViewCell).setPreviousMessage(aPrevMessage: nil)
            }
            
            (cell as! OutgoingGeneralUrlPreviewTempMessageTableViewCell).setModel(aMessage: model)
        }
        
        cell?.backgroundColor = .clear
        return cell!
    }
}



extension ChattingView: SBMessageInputViewDelegate {
    
    func inputViewDidTapButton(button: UIButton) {
        
    }
    func inputViewDidBeginEditing(textView: UITextView) {
        if UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft {
            textView.contentInset = UIEdgeInsets(top: textView.contentInset.top, left: textView.text.count > 0 ? 0.0 : 35.0, bottom: 0.0, right: 0.0)
        }
        else {
            textView.contentInset = UIEdgeInsets(top: textView.contentInset.top, left: 0.0, bottom: 0.0, right: textView.text.count > 0 ? 0.0 : 35.0)
        }
        textView.layoutIfNeeded()
    }
    
    func inputViewShouldBeginEditing(textView: UITextView) -> Bool {
        return true
    }
    func inputView(textView: UITextView, shouldChangeTextInRange: NSRange, replacementText: String) -> Bool {
        
        return true
    }
    
    func inputViewDidChange(textView: UITextView) {
        if textView.text.count > 0  {
            self.placeholderLabel.isHidden = true
            if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                self.btnCamera.isHidden = true
                textView.contentInset = UIEdgeInsets(top: textView.contentInset.top, left: 0.0, bottom: 0.0, right: 0.0)
                if self.cnTextViewTrailing.constant != 65.0 {
                    self.cnTextViewTrailing.constant = 65.0
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: {
                        self.layoutIfNeeded()
                    }) { (status) in
                        
                    }
                }
            }
            else {
                self.messageTextView.backgroundColor = .white
            }
            if self.delegate != nil {
                self.delegate?.startTyping(view: self)
            }
        }
        else {
            if UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft {
                textView.contentInset = UIEdgeInsets(top: textView.contentInset.top, left: 35.0, bottom: 0.0, right: 0.0)
            }
            else {
                textView.contentInset = UIEdgeInsets(top: textView.contentInset.top, left: 0.0, bottom: 0.0, right: 35.0)
            }
            
            self.placeholderLabel.isHidden = false
            self.messageTextView.backgroundColor = .clear
            if self.cnTextViewTrailing.constant != 12.0 {
                self.cnTextViewTrailing.constant = 12.0
                UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: {
                    self.layoutIfNeeded()
                    self.inputContainerViewHeight.constant = 44.0
                }) { (status) in
                    
                }
            }
            self.btnCamera.isHidden = false
            if self.delegate != nil {
                self.delegate?.endTyping(view: self)
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension ChattingView : UITextViewDelegate {

    // use auto-growing textfield here
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.messageTextView {
            
            if textView.text.count > 0  {
                
                self.placeholderLabel.isHidden = true
                if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    self.btnCamera.isHidden = true
                    if self.cnTextViewTrailing.constant != 65.0 {
                        self.cnTextViewTrailing.constant = 65.0
                        DispatchQueue.main.async {
                            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: {
                                self.layoutIfNeeded()
                            }) { (status) in
                                
                            }
                        }
                    }
                }
                if self.delegate != nil {
                    self.delegate?.startTyping(view: self)
                }
            }
            else {
                self.placeholderLabel.isHidden = false
                if self.cnTextViewTrailing.constant != 12.0 {
                    self.cnTextViewTrailing.constant = 12.0
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: {
                            self.layoutIfNeeded()
                        }) { (status) in
                            
                        }
                    }
                }
                self.btnCamera.isHidden = false
                if self.delegate != nil {
                    self.delegate?.endTyping(view: self)
                }
            }
            let cursorPosition = textView.caretRect(for: textView.selectedTextRange!.start).origin
            if cursorPosition.x.isInfinite == true || cursorPosition.y.isInfinite == true {
                return
            }
            
            var currentLine = Int(cursorPosition.y / 16.0 )
            if cursorPosition.x >= (textView.frame.size.width - 15.0) {
                currentLine = currentLine + 1
            }
            
            if previousLine > currentLine {
                UIView.animate(withDuration: 0.3) {
                    if currentLine == 0 {
                        self.inputContainerViewHeight.constant = 44.0
                        textView.isScrollEnabled = false
                    }
                    else if currentLine <= 5 {
                        textView.isScrollEnabled = false
                        self.inputContainerViewHeight.constant = self.inputContainerViewHeight.constant - 17.0 // Padding
                    }
                    else {
                        textView.isScrollEnabled = true
                    }
                }
            }
            else if previousLine < currentLine {
                UIView.animate(withDuration: 0.3) {
                    if currentLine == 0 {
                        self.inputContainerViewHeight.constant = 44.0
                        textView.isScrollEnabled = false
                    }
                    else if currentLine >= 5 {
                        textView.isScrollEnabled = true
                    }
                    else {
                        textView.isScrollEnabled = false
                        self.inputContainerViewHeight.constant = self.inputContainerViewHeight.constant + 17.0 // Padding
                    }
                }
            }
            
            textView.layoutIfNeeded()
            
            self.updateConstraints()
            previousLine = currentLine
        }
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool{
        return true
    }
}
