//
//  NSObject+Extenstion.swift
//  MessageCenter
//
//  Created by Ikarma Khan on 10/04/2019.
//

import Foundation


extension NSObject {
    class var string : String {
        get {
            return String(describing: self) // gives name of the class
        }
        set (key) {
            
        }
    }
    
    var className: String {
        return NSStringFromClass(type(of: self))
    }
}




