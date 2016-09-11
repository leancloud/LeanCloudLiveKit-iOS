//
//  LCLKLiveService.m
//  Pods
//
//  Created by 陈宜龙 on 16/9/9.
//
//

#import "LCLKLiveService.h"
#import "LCCKSessionService.h"

@implementation LCLKLiveService

- (void)fetchConversationIfNeededForLiveId:(NSString *)liveId callback:(AVIMConversationResultBlock)callback {
    AVIMConversationQuery *query = [[LCCKSessionService sharedInstance].client conversationQuery];
    [query whereKey:@"name" equalTo:liveId];
    query.cachePolicy = kAVCachePolicyNetworkElseCache;
    [query findConversationsWithCallback: ^(NSArray *objects, NSError *error) {
        if (error) {
            !callback ?: callback(nil, error);
            return;
        }
        if (objects.count > 0) {
            AVIMConversation *conversation = objects[0];
            !callback ?: callback(conversation, nil);
            return;
        }
        [[[LCCKSessionService sharedInstance] client] createConversationWithName:liveId clientIds:@[] attributes:nil options:AVIMConversationOptionTransient callback:callback];
    }];
}

@end
