//
//  LCLKLiveLikeMessage.m
//  高仿映客
//
//  Created by 陈宜龙 on 16/7/29.
//  Copyright © 2016年 JIAAIR. All rights reserved.
//

#import "LCLKLiveLikeMessage.h"

@implementation LCLKLiveLikeMessage

+ (AVIMMessageMediaType)classMediaType {
    return LCLKMessageTypeLike;
}

+ (void)load {
    // 自定义消息需要注册
    [self registerSubclass];
}

@end
