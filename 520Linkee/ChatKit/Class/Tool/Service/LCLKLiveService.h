//
//  LCLKLiveService.h
//  Pods
//
//  Created by 陈宜龙 on 16/9/9.
//
//

#import "LCCKServiceDefinition.h"
#import "LCCKConstants.h"

@interface LCLKLiveService : LCCKSingleton

#pragma mark - LCLKLiveService StreamingInfo
///=============================================================================
/// @name LCLKLiveService StreamingInfo
///=============================================================================

/*!
 *  @brief The block to execute with the users' information for the userIds. Always execute this block at some point when fetching StreamingInfo completes on main thread. Specify users' information how you want ChatKit to show.
 * @param streamingInfo Json String or NSDictionary
 *  @attention If you fetch users fails, you should reture nil, meanwhile, give the error reason.
 */
typedef void(^LCCKFetchStreamingInfoCompletionHandler)(id streamingInfo, NSError *error);

/*!
 *  @brief When LeanCloudChatKit wants to fetch StreamingInfo, this block will be invoked.
 *  @param liveId liveId
 *  @param completionHandler The block to execute with the Streaming information for the live. Always execute this block at some point during your implementation of this method on main thread. Specify users' information how you want ChatKit to show.
 */
typedef void(^LCCKFetchStreamingInfoBlock)(NSString *liveId, LCCKFetchStreamingInfoCompletionHandler completionHandler);

@property (nonatomic, copy) LCCKFetchStreamingInfoBlock fetchStreamingInfoBlock;

/*!
 *  @brief Add the ablitity to fetch StreamingInfo.
 *  @attention  You must get information with a synchronous implementation.
 *              If implemeted, this block will be invoked automatically for fetching StreamingInfo.
 */
- (void)setFetchStreamingInfoBlock:(LCCKFetchStreamingInfoBlock)fetchStreamingInfoBlock;

#pragma mark - LCLKLiveService PlayerInfo
///=============================================================================
/// @name LCLKLiveService PlayerInfo
///=============================================================================

/*!
 *  @brief The block to execute with the users' information for the userIds. Always execute this block at some point when fetching PlayerInfo completes on main thread. Specify users' information how you want ChatKit to show.
 * @param PlayerInfo NSURL or String or NSDictionary
 *  @attention If you fetch users fails, you should reture nil, meanwhile, give the error reason.
 */
typedef void(^LCCKFetchPlayerInfoCompletionHandler)(id PlayerInfo, NSError *error);

/*!
 *  @brief When LeanCloudChatKit wants to fetch PlayerInfo, this block will be invoked.
 *  @param liveId liveId
 *  @param completionHandler The block to execute with the player information for the live. Always execute this block at some point during your implementation of this method on main thread. Specify users' information how you want ChatKit to show.
 */
typedef void(^LCCKFetchPlayerInfoBlock)(NSString *liveId, LCCKFetchPlayerInfoCompletionHandler completionHandler);

@property (nonatomic, copy) LCCKFetchPlayerInfoBlock fetchPlayerInfoBlock;

/*!
 *  @brief Add the ablitity to fetch PlayerInfo.
 *  @attention  You must get information with a synchronous implementation.
 *              If implemeted, this block will be invoked automatically for fetching player information.
 */
- (void)setFetchPlayerInfoBlock:(LCCKFetchPlayerInfoBlock)fetchPlayerInfoBlock;
- (void)fetchConversationIfNeededForLiveId:(NSString *)liveId callback:(AVIMConversationResultBlock)callback;
@end
