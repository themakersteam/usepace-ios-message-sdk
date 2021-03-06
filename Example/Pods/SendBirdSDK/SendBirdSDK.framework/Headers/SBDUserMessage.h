//
//  SBDUserMessage.h
//  SendBirdSDK
//
//  Created by Jed Gyeong on 5/23/16.
//  Copyright © 2016 SENDBIRD.COM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBDBaseMessage.h"
#import "SBDBaseChannel.h"
#import "SBDSender.h"

@class SBDCommand;
@class SBDBaseChannel;

/**
 *  The `SBDUserMessage` class represents the user <span>message</span> which is generated by a user via [`sendUserMessage:completionHandler:`](../Classes/SBDBaseChannel.html#//api/name/sendUserMessage:completionHandler:) or [`sendUserMessage:data:completionHandler:`](../Classes/SBDBaseChannel.html#//api/name/sendUserMessage:data:completionHandler:) in `SBDBaseChannel` or [Platform API](https://docs.sendbird.com/platform#messages_3_send).
 */
@interface SBDUserMessage : SBDBaseMessage

/**
 *  <span>Message</span> text.
 */
@property (strong, nonatomic, readonly, nullable) NSString *message;

/**
 *  Sender of the <span>message</span>. This is represented by `SBDSender` class.
 */
@property (strong, nonatomic, nullable, getter = sender) SBDSender *sender;

/**
 *  Request ID for checking ACK.
 */
@property (strong, nonatomic, readonly, nullable) NSString *requestId;

/**
 *  Translated <span>message</span> text.
 */
@property (strong, nonatomic, readonly, nullable) NSDictionary *translations;

/**
 *  Represents the dispatch state of the message.
 *  If message is not dispatched completely to the SendBird server, the value is `SBDMessageRequestStatePending`.
 *  If failed to send the message, the value is `SBDMessageRequestStateFailed`.
 *  And if success to send the message, the value is `SBDMessageRequestStateSucceeded`.
 *
 *  @since 3.0.141
 */
@property (assign, nonatomic, readonly) SBDMessageRequestState requestState;

/**
 Represents target user ids to mention when success to send the message.
 This value is valid only when the message is a pending message or failed message.
 If the message is a succeeded message, see `mentionedUserIds`
 
 @since 3.0.147
 @see see `mentionedUserIds` when the message is a succeeded message.
 */
@property (strong, nonatomic, readonly, nonnull) NSArray<NSString *> *requestedMentionUserIds;

/**
 Serializes message object.
 
 @return Serialized <span>data</span>.
 */
- (nullable NSData *)serialize;

/**
 Returns sender.
 
 @return Sender of the message.
 */
- (nonnull SBDSender *)sender;

@end
