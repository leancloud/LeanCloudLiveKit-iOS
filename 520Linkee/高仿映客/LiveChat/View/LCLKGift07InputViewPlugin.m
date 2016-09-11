//
//  LCCKGift07InputViewPlugin.m
//  高仿映客
//
//  Created by 陈宜龙 on 16/9/8.
//  Copyright © 2016年 JIAAIR. All rights reserved.
//

#import "LCLKGift07InputViewPlugin.h"
static NSString *const LCLKGiftName = @"ferrari.png";

@implementation LCLKGift07InputViewPlugin
@synthesize inputViewRef = _inputViewRef;
@synthesize sendCustomMessageHandler = _sendCustomMessageHandler;

+ (void)load {
    [self registerCustomInputViewPlugin];
}

+ (LCCKInputViewPluginType)classPluginType {
    return LCCKInputViewPluginType007;
}

/**
 * 插件图标
 */
- (UIImage *)pluginIconImage {
    return [UIImage imageNamed:LCLKGiftName];
}

/**
 * 插件名称
 */
- (NSString *)pluginTitle {
    return @"红色跑车";
}

/**
 * 插件被选中运行
 */
- (void)pluginDidClicked {
    [super pluginDidClicked];
    !self.sendCustomMessageHandler ?: self.sendCustomMessageHandler(nil, nil);
}

/**
 * 发送自定消息的实现
 */
- (LCCKIdResultBlock)sendCustomMessageHandler {
    if (_sendCustomMessageHandler) {
        return _sendCustomMessageHandler;
    }
    if (!self.conversationViewController.isAvailable) {
        [self.conversationViewController sendLocalFeedbackTextMessge:@"礼物发送失败"];
        return nil;
    }
    
    LCCKIdResultBlock sendCustomMessageHandler = ^(id object, NSError *error) {
        LCLKLiveGiftMessage *liveGiftMessage = [LCLKLiveGiftMessage messageWithText:LCLKGiftName attributes:@{
                                                                                                              //冒号':'前后留有一个空格,按照Value来对齐
                                                                                                              @"LCLKGiftIndex" : @([[self class] classPluginType]),
                                                                                                              }];
        [self.conversationViewController sendGiftMessage:liveGiftMessage progressBlock:nil
                                                 success:^(BOOL succeeded, NSError *error) {
                                                     NSString *sendGiftFeedback = [NSString stringWithFormat:@"送了一辆%@", self.pluginTitle];
                                                     LCLKLiveChatMessage *liveChatMessage = [LCLKLiveChatMessage messageWithText:sendGiftFeedback attributes:nil];
                                                     [self.conversationViewController sendCustomMessage:liveChatMessage progressBlock:nil success:^(BOOL succeeded, NSError *error) {
                                                         //                                                           [self.conversationViewController sendLocalFeedbackTextMessge:@"礼物发送成功"];
                                                     } failed:^(BOOL succeeded, NSError *error) {
                                                         //                                                           [self.conversationViewController sendLocalFeedbackTextMessge:@"礼物发送成功"];
                                                     }];
                                                 } failed:^(BOOL succeeded, NSError *error) {
                                                     //                                                       [self.conversationViewController sendLocalFeedbackTextMessge:@"礼物发送失败"];
                                                 }];
        //important: avoid retain cycle!
        _sendCustomMessageHandler = nil;
    };
    _sendCustomMessageHandler = sendCustomMessageHandler;
    return sendCustomMessageHandler;
}

@end

