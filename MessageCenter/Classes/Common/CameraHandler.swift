//
//  CameraHandler.swift
//  MessageCenter
//
//  Created by Ikarma Khan on 03/07/2019.
//  Copyright © 2019 Ikarma Khan. All rights reserved.
//

import Foundation
import UIKit


class CameraHandler: NSObject,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    static let shared = CameraHandler()
    
    let myPickerController = UIImagePickerController()
    
    fileprivate var currentVC: UIViewController!
    
    //MARK: Internal Properties
    var imagePickedBlock: ((UIImage) -> Void)?
    
    func camera() {
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            myPickerController.delegate = self;
            myPickerController.sourceType = .camera
            currentVC.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func photoLibrary() {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            myPickerController.delegate = self;
            myPickerController.sourceType = .photoLibrary
            currentVC.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func showActionSheet(vc: UIViewController,sender: Any) {
        currentVC = vc
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "ms_camera".localized, style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.camera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "ms_photos".localized, style: .default, handler: { (alert:UIAlertAction!) -> Void in
            self.photoLibrary()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = vc.view
        }
        
        vc.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        myPickerController.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imagePickedBlock?(image)
        }else{
            print("Something went wrong")
        }
        myPickerController.dismiss(animated: true, completion: nil)
        
    }
    
    
}

