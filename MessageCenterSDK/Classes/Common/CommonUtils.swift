//
//  CommonUtils.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/6/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import CryptoSwift
import AVFoundation
import Photos

class CommonUtils: NSObject {
    // Not being used
    static func imageFromColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    // Not being used
    static func generateNavigationTitle(mainTitle: String, subTitle: String?, titleColor: UIColor? , subTitleColor: UIColor?) -> NSAttributedString? {
        var mainTitleAttribute: [NSAttributedString.Key:AnyObject]
        var subTitleAttribute: [NSAttributedString.Key:AnyObject]?
        var fullTitle: NSMutableAttributedString
        
        mainTitleAttribute = [
            NSAttributedString.Key.font: Constants.navigationBarTitleFont,
            NSAttributedString.Key.foregroundColor: titleColor != nil ? titleColor! : Constants.navigationBarTitleColor
            ] as [NSAttributedString.Key : AnyObject]
        fullTitle = NSMutableAttributedString(string: mainTitle)
        fullTitle.addAttributes(mainTitleAttribute, range: NSMakeRange(0, mainTitle.count))
        
        if let theSubTitle: String = subTitle {
            subTitleAttribute = [
                NSAttributedString.Key.font: Constants.navigationBarSubTitleFont,
                NSAttributedString.Key.foregroundColor: subTitleColor != nil ? subTitleColor! : Constants.navigationBarSubTitleColor
                ] as [NSAttributedString.Key : AnyObject]
            fullTitle.append(NSAttributedString(string: "\n\(theSubTitle)"))
            fullTitle.addAttributes(subTitleAttribute!, range: NSMakeRange(mainTitle.count + 1, (subTitle?.count)!))
        }
        
        return fullTitle
    }
    
    // Being used
    static func dumpMessages(messages: [SBDBaseMessage], resendableMessages: [String: SBDBaseMessage], resendableFileData: [String: [String: Any]], preSendMessages: [String: SBDBaseMessage], channelUrl: String) {
        var from = 0
        
        if messages.count == 0 {
            return
        }
        
        if messages.count > 100 {
            from = messages.count - 100
        }
        
        var serializedMessages: [String] = []
        for startIndex in from..<messages.count {
            var requestId: String?
            if let message = messages[startIndex] as? SBDUserMessage {
                requestId = message.requestId
            }
            
            else if let message = messages[startIndex] as? SBDFileMessage {
                requestId = message.requestId
            }
            
            if let theRequestId: String = requestId {
                if resendableMessages[theRequestId] != nil {
                    continue
                }
                
                if preSendMessages[theRequestId] != nil {
                    continue
                }
                
                if resendableFileData[theRequestId] != nil {
                    continue
                }
            }
            
            let messageData = messages[startIndex].serialize()
            let messageString = messageData?.base64EncodedString()
            serializedMessages.append(messageString!)
        }
        
        let dumpedMessages = serializedMessages.joined(separator: "\n")
        let dumpedMessagesHash = CommonUtils.sha256(string: dumpedMessages)
        
        // Save messages to temp file.
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = paths[0] as NSString
        let appIdDirectory = documentsDirectory.appendingPathComponent(SBDMain.getApplicationId()!) as NSString
        
        let uniqueTempFileNamePrefix = UUID().uuidString
        let tempMessageDumpFileName = String(format: "%@.data", uniqueTempFileNamePrefix)
        let tempMessageHashFileName = String(format: "%@.hash", uniqueTempFileNamePrefix)
        
        let tempMessageDumpFilePath = appIdDirectory.appendingPathComponent(tempMessageDumpFileName)
        let tempMessageHashFilePath = appIdDirectory.appendingPathComponent(tempMessageHashFileName)
        
        if FileManager.default.fileExists(atPath: appIdDirectory as String) == false {
            do {
                try FileManager.default.createDirectory(atPath: appIdDirectory as String, withIntermediateDirectories: false, attributes: nil)
            }
            catch {
                return
            }
        }
        if SBDMain.getCurrentUser() == nil {
            return
        }
        
        let messageFileNamePrefix = CommonUtils.sha256(string: String(format: "%@_%@", (SBDMain.getCurrentUser()?.userId.urlencoding())!, channelUrl))
        let messageDumpFileName = String(format: "%@.data", messageFileNamePrefix!)
        let messageHashFileName = String(format: "%@.hash", messageFileNamePrefix!)
        
        let messageDumpFilePath = appIdDirectory.appendingPathComponent(messageDumpFileName)
        let messageHashFilePath = appIdDirectory.appendingPathComponent(messageHashFileName)
        
        // Check hash
        var previousHash: String?
        if FileManager.default.fileExists(atPath: messageDumpFilePath) == false {
            FileManager.default.createFile(atPath: messageDumpFilePath, contents: nil, attributes: nil)
        }
        
        if FileManager.default.fileExists(atPath: messageHashFilePath) == false {
            FileManager.default.createFile(atPath: messageHashFilePath, contents: nil, attributes: nil)
        }
        else {
            do {
                try previousHash = String.init(contentsOfFile: messageHashFilePath)
            }
            catch {
                return
            }
        }
        
        if previousHash == dumpedMessagesHash {
            return
        }
        
        // Write temp file.
        do {
            try dumpedMessages.write(toFile: tempMessageDumpFilePath, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {
            return
        }
        
        do {
            try dumpedMessagesHash?.write(toFile: tempMessageHashFilePath, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {
            return
        }
        
        // Move temp to real file.
        do {
            try FileManager.default.removeItem(atPath: messageDumpFilePath)
            try FileManager.default.moveItem(atPath: tempMessageDumpFilePath, toPath: messageDumpFilePath)

            try FileManager.default.removeItem(atPath: messageHashFilePath)
            try FileManager.default.moveItem(atPath: tempMessageHashFilePath, toPath: messageHashFilePath)

            try FileManager.default.removeItem(atPath: tempMessageDumpFilePath)
            try FileManager.default.removeItem(atPath: tempMessageHashFilePath)
            try FileManager.default.removeItem(atPath: messageDumpFilePath)
            try FileManager.default.removeItem(atPath: messageHashFilePath)
        }
        catch {
            return
        }
    }
    
    static func loadMessagesInChannel(channelUrl: String) -> [SBDBaseMessage] {
        
        guard let appID = SBDMain.getApplicationId(),
            let user = SBDMain.getCurrentUser(),
            let messageFileNamePrefix = CommonUtils.sha256(string: String(format: "%@_%@", user.userId.urlencoding(), channelUrl))  else {
                return []
        
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = paths[0] as NSString
        let appIdDirectory = documentsDirectory.appendingPathComponent(appID) as NSString
        let dumpFileName = String(format: "%@.data", messageFileNamePrefix) //as NSString
        let dumpFilePath = appIdDirectory.appendingPathComponent(dumpFileName ) //as String
        
        if FileManager.default.fileExists(atPath: dumpFilePath) == false {
            return []
        }
        
        do {
            let messageDump = try String(contentsOfFile: dumpFilePath, encoding: String.Encoding.utf8)
            
            if messageDump.count > 0 {
                let loadMessages = messageDump.components(separatedBy: "\n")
                
                if loadMessages.count > 0 {
                    var messages: [SBDBaseMessage] = []
                    for msgString in loadMessages {
                        if let msgData = NSData(base64Encoded: msgString, options: NSData.Base64DecodingOptions(rawValue: UInt(0))),
                            let message = SBDBaseMessage.build(fromSerializedData: msgData as Data) {
                            messages.append(message)
                        }
                    }
                    return messages
                }
            }
        }
        catch {
            return []
        }
        return []
    }
    
    // Not being used
    static func dumpChannels(channels: [SBDBaseChannel]) {
        // Serialize channels
        var from = 0
        
        if channels.count == 0 {
            return
        }
        
        if channels.count > 100 {
            from = channels.count - 100
        }
        
        var serializedChannels: [String] = []
        for startIndex in from..<channels.count {
            let channelData = channels[startIndex].serialize()
            let channelString = channelData?.base64EncodedString()
            serializedChannels.append(channelString!)
        }
        
        let dumpedChannels = serializedChannels.joined(separator: "\n")
        let dumpedChannelsHash = CommonUtils.sha256(string: dumpedChannels)
        
        // Save channels to temp file.
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = paths[0] as NSString
        let appIdDirectory = documentsDirectory.appendingPathComponent(SBDMain.getApplicationId()!) as NSString
        
        let uniqueTempFileNamePrefix = UUID().uuidString
        let tempChannelDumpFileName = String(format: "%@_channellist.data", uniqueTempFileNamePrefix)
        let tempChannelHashFileName = String(format: "%@_channellist.hash", uniqueTempFileNamePrefix)
        
        let tempChannelDumpFilePath = appIdDirectory.appendingPathComponent(tempChannelDumpFileName)
        let tempChannelHashFilePath = appIdDirectory.appendingPathComponent(tempChannelHashFileName)
        
        if FileManager.default.fileExists(atPath: appIdDirectory as String) == false {
            do {
                try FileManager.default.createDirectory(atPath: appIdDirectory as String, withIntermediateDirectories: false, attributes: nil)
            }
            catch {
                return
            }
        }
        
        let channelFileNamePrefix = CommonUtils.sha256(string: String(format: "%@_channellist", (SBDMain.getCurrentUser()?.userId.urlencoding())!))
        let channelDumpFileName = String(format: "%@.data", channelFileNamePrefix!)
        let channelHashFileName = String(format: "%@.hash", channelFileNamePrefix!)
        
        let channelDumpFilePath = appIdDirectory.appendingPathComponent(channelDumpFileName)
        let channelHashFilePath = appIdDirectory.appendingPathComponent(channelHashFileName)
        
        // Check hash
        var previousHash: String?
        if FileManager.default.fileExists(atPath: channelDumpFilePath) == false {
            FileManager.default.createFile(atPath: channelDumpFilePath, contents: nil, attributes: nil)
        }
        
        if FileManager.default.fileExists(atPath: channelHashFilePath) == false {
            FileManager.default.createFile(atPath: channelHashFilePath, contents: nil, attributes: nil)
        }
        else {
            do {
                try previousHash = String.init(contentsOfFile: channelHashFilePath)
            }
            catch {
                return
            }
        }
        
        if previousHash == dumpedChannelsHash {
            return
        }
        
        // Write temp file.
        do {
            try dumpedChannels.write(toFile: tempChannelDumpFilePath, atomically: false, encoding: String.Encoding.utf8)
            try dumpedChannelsHash?.write(toFile: tempChannelHashFilePath, atomically: false, encoding: String.Encoding.utf8)
        }
        catch {
            return
        }
        
        // Move temp to real file.
        do {
            try FileManager.default.removeItem(atPath: channelDumpFilePath)
            try FileManager.default.moveItem(atPath: tempChannelDumpFilePath, toPath: channelDumpFilePath)
            
            try FileManager.default.removeItem(atPath: channelHashFilePath)
            try FileManager.default.moveItem(atPath: tempChannelHashFilePath, toPath: channelHashFilePath)
            
            try FileManager.default.removeItem(atPath: tempChannelDumpFilePath)
            try FileManager.default.removeItem(atPath: tempChannelHashFilePath)
            try FileManager.default.removeItem(atPath: channelDumpFilePath)
            try FileManager.default.removeItem(atPath: channelHashFilePath)
        }
        catch {
            return
        }
    }
    
    // Not being used
    static func loadGroupChannels() -> [SBDGroupChannel] {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = paths[0] as NSString
        let messageFileNamePrefix = CommonUtils.sha256(string: String(format: "%@_channellist", (SBDMain.getCurrentUser()?.userId.urlencoding())!))! as NSString
        let dumpFileName = String(format: "%@.data", messageFileNamePrefix) as NSString
        let appIdDirectory = documentsDirectory.appendingPathComponent(SBDMain.getApplicationId()!) as NSString
        let dumpFilePath = appIdDirectory.appendingPathComponent(dumpFileName as String)
        
        if FileManager.default.fileExists(atPath: dumpFilePath) == false {
            return []
        }
        
        do {
            let channelDump = try String(contentsOfFile: dumpFilePath, encoding: String.Encoding.utf8)
            
            if channelDump.count > 0 {
                let loadChannels = channelDump.components(separatedBy: "\n")
                
                if loadChannels.count > 0 {
                    var channels: [SBDGroupChannel] = []
                    for channelString in loadChannels {
                        let channelData = NSData(base64Encoded: channelString, options: NSData.Base64DecodingOptions(rawValue: UInt(0)))
                        let channel = SBDGroupChannel.build(fromSerializedData: channelData! as Data)
                        channels.append(channel!)
                    }
                    
                    return channels
                }
            }
        }
        catch {
            return []
        }
        
        return []
    }
    
    static func sha256(string: String) -> String? {
        return string.sha256()
    }
    
    // Not being used
    static func findBestViewController(vc: UIViewController) -> UIViewController? {
        if vc.presentedViewController != nil {
            return CommonUtils.findBestViewController(vc: vc.presentedViewController!)
        }
        else if vc.isKind(of: UISplitViewController.self) {
            let svc = vc as! UISplitViewController
            if svc.viewControllers.count > 0 {
                return CommonUtils.findBestViewController(vc: svc.viewControllers.last!)
            }
            else {
                return vc
            }
        }
        else if vc.isKind(of: UINavigationController.self) {
            let svc = vc as! UINavigationController
            if svc.viewControllers.count > 0 {
                return CommonUtils.findBestViewController(vc: svc.topViewController!)
            }
            else {
                return vc
            }
        }
        else if vc.isKind(of: UITabBarController.self) {
            let svc = vc as! UITabBarController
            if (svc.viewControllers?.count)! > 0 {
                return CommonUtils.findBestViewController(vc: svc.selectedViewController!)
            }
            else {
                return vc
            }
        }
        else {
            return vc
        }
    }
    
    
    static func getDirectoryPath() -> NSURL {
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("MessageCenter")
        let url = NSURL(string: path)
        return url!
    }
    
    static func saveImageDocumentDirectory(image: UIImage, imageName: String) {
        let fileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("MessageCenter")
        if !fileManager.fileExists(atPath: path) {
            try! fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        let url = NSURL(string: path)
        let imagePath = url!.appendingPathComponent(imageName)
        let urlString: String = imagePath!.absoluteString
        let imageData =  image.jpegData(compressionQuality: 1.0)
        //let imageData = UIImagePNGRepresentation(image)
        fileManager.createFile(atPath: urlString as String, contents: imageData, attributes: nil)
    }
    
    static func getImageFromDocumentDirectory(_ name: String) -> UIImage? {
        let fileManager = FileManager.default
        let imagePath = (CommonUtils.getDirectoryPath() as NSURL).appendingPathComponent(name)
        let urlString: String = imagePath!.absoluteString
        if fileManager.fileExists(atPath: urlString) {
            let image = UIImage(contentsOfFile: urlString)
            return image
        } else {
            return nil
        }
    }
    
    
    static func showErrorAlertController (vc: UIViewController, title:String?, message:String?) {
        
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title?.localized, message: message?.localized, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "settings".localized, style: .default, handler: { action in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                }
            }))
            
            alert.addAction(UIAlertAction(title: "cancel".localized, style: .default, handler: { action in
                // cancelled
            }))
            
            vc.present(alert, animated: true, completion: nil)
        }
    }
}


extension UIImagePickerController {
    class func checkPermissionStatus(sourceType:UIImagePickerController.SourceType, completionBlockSuccess successBlock: @escaping ((Bool) -> ()), andFailureBlock failBlock: @escaping ((Bool) -> ())) {
        
        if sourceType == .photoLibrary || sourceType == .savedPhotosAlbum {
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    successBlock(true)
                }
                else if status == .denied || status == .restricted {
                    failBlock(false)
                }
            }
        }
        else if sourceType == .camera {
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .notDetermined {
                    AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (status) in
                        if status == true {
                            successBlock(true)
                        }
                        else {
                            failBlock(false)
                        }
                    })
                }
                else if status == .denied || status == .restricted {
                    failBlock(true)
                }
                else if status == .authorized {
                    successBlock(false)
                }
            }
        }
        else {
            assert(false, "Permission type not found.")
        }
    }
}


extension UILabel {
    func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {
        
        guard let labelText = self.text else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        
        let attributedString:NSMutableAttributedString
        if let labelattributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelattributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }
        
        // Line spacing attribute
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        
        self.attributedText = attributedString
    }
}

