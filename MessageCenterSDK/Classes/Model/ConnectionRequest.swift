//
//  ConnectionRequest.swift
//  MessageCenter
//
//  Created by iDev on 11/1/18.
//  Copyright © 2018 usepace. All rights reserved.
//

import Foundation

public class ConnectionRequest {
    
    var appId: String = ""
    var userId: String = ""
    var accessToken: String = ""
    var client: ClientType = .sendBird
    var pushToken : Data?
    var unique : Bool?
    var channel : String?
    var channelId : String?
    
    public init(appId: String, userId: String, accessToken: String, client: ClientType, unique:Bool?) {
        self.appId = appId
        self.userId = userId
        self.accessToken = accessToken
        self.client = client
        self.unique = unique
    }
    
    public func updatePushToken(pushToken:Data?) {
        self.pushToken = pushToken
    }
    
    public func updateChannel (channel:String?) {
        self.channel = channel
    }
    
    public func updateChannelId (channelId:String?) {
        self.channelId = channelId
    }
    
}
