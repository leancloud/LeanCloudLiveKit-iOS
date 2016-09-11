
//
//  LCLKLiveDanmuMessage.m
//  高仿映客
//
//  Created by 陈宜龙 on 16/7/29.
//  Copyright © 2016年 JIAAIR. All rights reserved.
//

#import "LCLKLiveDanmuMessage.h"

@implementation LCLKLiveDanmuMessage

+ (AVIMMessageMediaType)classMediaType {
    return LCLKMessageTypeDanMu;
}

+ (void)load {
    // 自定义消息需要注册
    [self registerSubclass];
}

@end
