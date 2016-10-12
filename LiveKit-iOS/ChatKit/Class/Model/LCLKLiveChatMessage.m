//
//  LCLKLiveChatMessage.m
//  高仿映客
//
//  Created by 陈宜龙 on 16/7/27.
//  Copyright © 2016年 JIAAIR. All rights reserved.
//

#import "LCLKLiveChatMessage.h"

@implementation LCLKLiveChatMessage

+ (AVIMMessageMediaType)classMediaType {
    return LCLKMessageTypeTransient;
}

+ (void)load {
    // 自定义消息需要注册
    [self registerSubclass];
}

@end
