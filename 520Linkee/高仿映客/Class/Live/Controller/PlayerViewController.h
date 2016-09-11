//
//  PlayerViewController.h
//  高仿映客
//
//  Created by JIAAIR on 16/7/2.
//  Copyright © 2016年 JIAAIR. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - 颜色
// 颜色相关
#define Color(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define KeyColor Color(216, 41, 116)

@interface PlayerViewController : UIViewController

@property (nonatomic, strong)NSString * liveUrl;
@property (nonatomic, strong)NSString * imageUrl;

@end
