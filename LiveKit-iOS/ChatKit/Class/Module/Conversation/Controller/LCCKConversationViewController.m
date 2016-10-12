//
//  LCCKConversationViewController.m
//  LCCKChatBarExample
//
//  v0.7.10 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/20.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

//CYLDebugging定义为1表示【debugging】 ，注释、不定义或者0 表示【debugging】
//#define CYLDebugging 1

#import "LCCKConversationViewController.h"

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

#import "UIImageView+WebCache.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "LCCKCellRegisterController.h"
#import "LCCKStatusView.h"
#import "LCCKSoundManager.h"
#import "LCCKTextFullScreenViewController.h"
#import <objc/runtime.h>
#import "NSMutableArray+LCCKMessageExtention.h"
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif
#import "LCCKConversationNavigationTitleView.h"
#import "LCCKWebViewController.h"
#import "LCCKSafariActivity.h"
#import "LCCKAlertController.h"
#import "LCCKPhotoBrowser.h"

#ifdef CYLDebugging
#import <MLeaksFinder/MLeaksFinder.h>
#endif
#import "LCCKDeallocBlockExecutor.h"
NSString *const LCCKConversationViewControllerErrorDomain = @"LCCKConversationViewControllerErrorDomain";

@interface LCCKConversationViewController () <LCCKChatBarDelegate, LCCKAVAudioPlayerDelegate, LCCKChatMessageCellDelegate, LCCKConversationViewModelDelegate, LCCKPhotoBrowserDelegate>

@property (nonatomic, strong, readwrite) AVIMConversation *conversation;
//@property (copy, nonatomic) NSString *messageSender /**< 正在聊天的用户昵称 */;
//@property (copy, nonatomic) NSString *avatarURL /**< 正在聊天的用户头像 */;
/**< 正在聊天的用户 */
@property (nonatomic, copy) id<LCCKUserDelegate> user;
/**< 正在聊天的用户clientId */
@property (nonatomic, copy) NSString *userId;
/**< 正在聊天的用户头像 */
//@property (nonatomic, copy) NSURL *avatarURL;
@property (nonatomic, strong) LCCKConversationViewModel *chatViewModel;
@property (nonatomic, copy) LCCKFetchConversationHandler fetchConversationHandler;
@property (nonatomic, copy) LCCKLoadLatestMessagesHandler loadLatestMessagesHandler;
@property (nonatomic, copy, readwrite) NSString *conversationId;
@property (nonatomic, strong) LCCKWebViewController *webViewController;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbs;
@property (nonatomic, assign, getter=isFirstTimeJoinGroup) BOOL firstTimeJoinGroup;

@property (nonatomic, strong) UIButton *applauseButton; /**< 点赞出心 */
@property (strong, nonatomic) UILabel *applauseNumberLabel;
@property (assign, nonatomic) NSInteger applauseNumber;

@property (nonatomic, assign) CGFloat heartSize;
@property (nonatomic, weak) CALayer *fireworksL;
@property (nonatomic, strong) NSArray *fireworksArray;

@end

@implementation LCCKConversationViewController

- (void)setFetchConversationHandler:(LCCKFetchConversationHandler)fetchConversationHandler {
    _fetchConversationHandler = fetchConversationHandler;
}

- (void)setLoadLatestMessagesHandler:(LCCKLoadLatestMessagesHandler)loadLatestMessagesHandler {
    _loadLatestMessagesHandler = loadLatestMessagesHandler;
}

#pragma mark -
#pragma mark - initialization Method

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _conversationId = [conversationId copy];
    [self setup];
    return self;
}

- (instancetype)initWithPeerId:(NSString *)peerId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _peerId = [peerId copy];
    [self setup];
    return self;
}

- (AVIMConversation *)getConversationIfExists {
    if (_conversation) {
        return _conversation;
    }
    return nil;
}

/**
 *  lazy load conversation
 *
 *  @return AVIMConversation
 */
- (AVIMConversation *)conversation {
    if (_conversation) { return _conversation; }
    do {
        /* If object is clean, ignore save request. */
        if (_peerId) {
            [[LCCKConversationService sharedInstance] fecthConversationWithPeerId:self.peerId callback:^(AVIMConversation *conversation, NSError *error) {
                //SDK没有好友观念，任何两个ID均可会话，请APP层自行处理好友关系。
                [self refreshConversation:conversation isJoined:YES error:error];
            }];
            break;
        }
        /* If object is clean, ignore save request. */
        if (_conversationId) {
            [[LCCKConversationService sharedInstance] fecthConversationWithConversationId:self.conversationId callback:^(AVIMConversation *conversation, NSError *error) {
                if (error) {
                    //如果用户已经已经被踢出群，此时依然能拿到 Conversation 对象，不会报 4401 错误，需要单独判断。即使后期服务端在这种情况下返回error，这里依然能正确处理。
                    [self refreshConversation:conversation isJoined:NO error:error];
                    return;
                }
                NSString *currentClientId = [LCCKSessionService sharedInstance].clientId;
                //系统对话
                if (conversation.members.count == 0 && (conversation.transient == NO)) {
                    [self refreshConversation:conversation isJoined:YES];
                    return;
                }
                BOOL containsCurrentClientId = [conversation.members containsObject:currentClientId];
                if (containsCurrentClientId) {
                    [self refreshConversation:conversation isJoined:YES];
                    return;
                }
                if (self.isEnableAutoJoin) {
                    [conversation joinWithCallback:^(BOOL succeeded, NSError *error) {
                        [self refreshConversation:conversation isJoined:succeeded error:error];
                        if (succeeded) {
                            self.firstTimeJoinGroup = YES;
                        }
                    }];
                } else {
                    NSInteger code = 4401;
                    //错误码参考：https://leancloud.cn/docs/realtime_v2.html#%E4%BA%91%E7%AB%AF%E9%94%99%E8%AF%AF%E7%A0%81%E8%AF%B4%E6%98%8E
                    NSString *errorReasonText = @"INVALID_MESSAGING_TARGET 您已被被管理员移除该群";
                    NSDictionary *errorInfo = @{
                                                @"code":@(code),
                                                NSLocalizedDescriptionKey : errorReasonText,
                                                };
                    NSError *error_ = [NSError errorWithDomain:NSStringFromClass([self class])
                                                          code:code
                                                      userInfo:errorInfo];
                    [self refreshConversation:conversation isJoined:NO error:error_];
                }
            }];
            break;
        }
    } while (NO);
    return _conversation;
}

#pragma mark - Life Cycle

- (void)setup {
    self.allowScrollToBottom = YES;
    self.loadingMoreMessage = NO;
    self.disableTextShowInFullScreen = NO;
    BOOL clientStatusOpened = [LCCKSessionService sharedInstance].client.status == AVIMClientStatusOpened;
    //    NSAssert(clientStatusOpened, @"client not opened");
    if (!clientStatusOpened) {
        [self refreshConversation:nil isJoined:NO];
        [[LCCKSessionService sharedInstance] reconnectForViewController:self callback:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [self conversation];
            }
        }];
    }
}

#ifdef CYLDebugging
- (BOOL)willDealloc {
    if (![super willDealloc]) {
        return NO;
    }
    MLCheck(self.chatViewModel);
    return YES;
}
#endif


/**
 *  lazy load chatViewModel
 *
 *  @return LCCKConversationViewModel
 */
- (LCCKConversationViewModel *)chatViewModel {
    if (_chatViewModel == nil) {
        LCCKConversationViewModel *chatViewModel = [[LCCKConversationViewModel alloc] initWithParentViewController:self];
        chatViewModel.delegate = self;
        _chatViewModel = chatViewModel;
    }
    return _chatViewModel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //FIXME:
    [LCCKConversationService sharedInstance].danMuMessage = NO;
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
    self.tableView.delegate = self.chatViewModel;
    self.tableView.dataSource = self.chatViewModel;
    self.chatBar.delegate = self;
    [LCCKAVAudioPlayer sharePlayer].delegate = self;
    [self.view addSubview:self.chatBar];
    [self.view addSubview:self.clientStatusView];
    [self updateStatusView];
    [self initBarButton];
    [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserDelegate> user, NSError *error) {
        self.user = user;
    }];
    [self.chatViewModel setDefaultBackgroundImage];
    self.navigationItem.title = @"聊天";
    [self.applauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.view).offset(-10);
        //        make.width.and.height.mas_equalTo(50);
        make.bottom.mas_equalTo(self.chatBar.mas_top).offset(-10);
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customTransientMessageReceived:) name:LCCKNotificationCustomTransientMessageReceived object:nil];
        __unsafe_unretained typeof(self) weakSelf = self;
        [self lcck_executeAtDealloc:^{
               [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
        [weakSelf.renderer stop];
        [weakSelf.renderer.view removeFromSuperview];
        weakSelf.renderer = nil;
    }];
    [self renderer];
    [_renderer start];
    [self conversation];
    !self.viewDidLoadBlock ?: self.viewDidLoadBlock(self);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    !self.viewWillAppearBlock ?: self.viewWillAppearBlock(self, animated);
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.chatBar open];
    [self saveCurrentConversationInfoIfExists];
    !self.viewDidAppearBlock ?: self.viewDidAppearBlock(self, animated);
}

- (void)loadDraft {
    [self.chatBar appendString:_conversation.lcck_draft];
    [self.chatBar beginInputing];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    [self.chatBar close];
    NSString *conversationId = [self getConversationIdIfExists:nil];
    if (conversationId) {
        [[LCCKConversationService sharedInstance] updateDraft:self.chatBar.cachedText conversationId:conversationId];
    }
    [self clearCurrentConversationInfo];
    [[LCCKAVAudioPlayer sharePlayer] stopAudioPlayer];
    [LCCKAVAudioPlayer sharePlayer].identifier = nil;
    [LCCKAVAudioPlayer sharePlayer].URLString = nil;
    !self.viewWillDisappearBlock ?: self.viewWillDisappearBlock(self, animated);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_conversation && (self.chatViewModel.avimTypedMessage.count > 0)) {
        [[LCCKConversationService sharedInstance] updateConversationAsRead];
    }
    !self.viewDidDisappearBlock ?: self.viewDidDisappearBlock(self, animated);
}

- (void)dealloc {
    _chatViewModel.delegate = nil;
    [[LCCKAVAudioPlayer sharePlayer] setDelegate:nil];
    !self.viewControllerWillDeallocBlock ?: self.viewControllerWillDeallocBlock(self);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    !self.didReceiveMemoryWarningBlock ?: self.didReceiveMemoryWarningBlock(self);
}

#pragma mark -
#pragma mark - public Methods
//FIXME:
- (void)autoSendBarrage {
    //    [self showTheLove:self.heartBtn];
    [self applauseButtonClick];
    NSInteger spriteNumber = [_renderer spritesNumberWithName:nil];
    if (spriteNumber <= 50) { // 限制屏幕上的弹幕量
        [_renderer receive:[self walkTextSpriteDescriptorWithDirection:BarrageWalkDirectionR2L]];
    }
}

- (void)sendBarrageText:(NSString *)text {
    NSInteger spriteNumber = [_renderer spritesNumberWithName:nil];
    if (spriteNumber <= 50) { // 限制屏幕上的弹幕量
        [_renderer receive:[self walkTextSpriteDescriptorWithDirection:BarrageWalkDirectionR2L text:text]];
    }
}

#pragma mark - 弹幕描述符生产方法

long _index = 0;
/// 生成精灵描述 - 过场文字弹幕
- (BarrageDescriptor *)walkTextSpriteDescriptorWithDirection:(NSInteger)direction {
    return [self walkTextSpriteDescriptorWithDirection:direction text:self.danMuText[arc4random_uniform((uint32_t)self.danMuText.count)]];
}


/// 生成精灵描述 - 过场文字弹幕
- (BarrageDescriptor *)walkTextSpriteDescriptorWithDirection:(NSInteger)direction text:(NSString *)text {
    BarrageDescriptor * descriptor = [[BarrageDescriptor alloc]init];
    descriptor.spriteName = NSStringFromClass([BarrageWalkTextSprite class]);
    //TODO:弹幕的字幕设置
    descriptor.params[@"text"] = text;
    descriptor.params[@"textColor"] = Color(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256));
    descriptor.params[@"speed"] = @(100 * (double)random()/RAND_MAX+50);
    descriptor.params[@"direction"] = @(direction);
    descriptor.params[@"clickAction"] = ^{
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"弹幕被点击" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
        [alertView show];
    };
    return descriptor;
}

- (NSArray *)danMuText {
    NSArray *array = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"danmu.plist" ofType:nil]];
    return array;
}

- (void)danMuMessageReceived:(AVIMTypedMessage *)message {
    //FIXME:
    NSString *text = message.text;
    [self sendBarrageText:text];
}

- (void)danMuMessageSended:(NSNotification *)notification {
    //FIXME:
    NSString *text = notification.object;
    [self sendBarrageText:text];
}

#pragma mark - Getters

/**
 *  lazy load renderer
 *
 *  @return BarrageRenderer
 */
- (BarrageRenderer *)renderer {
    if (_renderer == nil) {
        BarrageRenderer *renderer = [[BarrageRenderer alloc] init];
        renderer.canvasMargin = UIEdgeInsetsMake([UIScreen mainScreen].bounds.size.height * 0.3, 10, 10, 10);
        _renderer = renderer;
    }
    return _renderer;
}

- (void)customTransientMessageReceived:(NSNotification *)notification {
    NSDictionary *userInfo = notification.object;
    if (!userInfo) {
        return;
    }
    
    AVIMTypedMessage *typedMessage = userInfo[LCCKDidReceiveCustomMessageUserInfoMessageKey];
    AVIMConversation *conversation = userInfo[LCCKDidReceiveMessagesUserInfoConversationKey];
    BOOL isCurrentConversationMessage = [conversation.conversationId isEqualToString:self.conversationId];
    if (!isCurrentConversationMessage) {
        return;
    }
    //    //TODO:弹幕消息、点赞出心消息不展示到消息列表中
    //    if ([aMessage lcck_isCustomMessage] ) {
    //        AVIMTypedMessage *typedMessage = (AVIMTypedMessage *)aMessage;
    //        BOOL shoudPreviewToChatList = (typedMessage.mediaType == LCLKMessageTypeDanMu) || (typedMessage.mediaType == LCLKMessageTypeLike) || (typedMessage.mediaType  == LCLKMessageTypeGift);
    //        if (shoudPreviewToChatList){
    //            !callback ?: callback();
    //            return;
    //        }
    //    }
    
    if (typedMessage.mediaType == LCLKMessageTypeLike) {
        //        [self showTheLove:self.heartBtn];
        [self applauseButtonClick];
        return;
    }
    
    if (typedMessage.mediaType == LCLKMessageTypeDanMu) {
        NSString *text = typedMessage.text;
        [self sendBarrageText:text];
        return;
    }
    
    if (typedMessage.mediaType == LCLKMessageTypeGift) {
        NSUInteger index = [[typedMessage.attributes valueForKey:@"LCLKGiftIndex"] integerValue];
        [self showMyPorsche918WithImageName:typedMessage.text index:(index - 1)];
        return;
    }
    
}

- (void)sendTextMessage:(NSString *)text {
    if ([text length] > 0 ) {
        BOOL isDanMuMessage = [LCCKConversationService sharedInstance].isDanMuMessage;
        id message;
        if (isDanMuMessage) {
            LCLKLiveDanmuMessage *danMuMessage = [LCLKLiveDanmuMessage messageWithText:text attributes:nil];
            message = danMuMessage;
        } else {
            LCLKLiveChatMessage *liveChatMessage = [LCLKLiveChatMessage messageWithText:text attributes:nil];
            message = liveChatMessage;
        }
        [self makeSureSendValidMessage:message afterFetchedConversationShouldWithAssert:NO];
        [self.chatViewModel sendCustomMessage:message progressBlock:nil success:^(BOOL succeeded, NSError *error) {
            if (isDanMuMessage) {
                [self sendBarrageText:text];
            }
        } failed:^(BOOL succeeded, NSError *error) {
            
        }];
    }
}

- (void)sendImages:(NSArray<UIImage *> *)pictures {
    for (UIImage *image in pictures) {
        [self sendImageMessage:image];
    }
}

- (void)sendImageMessage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    [self sendImageMessageData:imageData];
}

- (void)sendImageMessageData:(NSData *)imageData {
    NSString *path = [[LCCKSettingService sharedInstance] tmpPath];
    NSError *error;
    [imageData writeToFile:path options:NSDataWritingAtomic error:&error];
    UIImage *representationImage = [[UIImage alloc] initWithData:imageData];
    UIImage *thumbnailPhoto = [representationImage lcck_imageByScalingAspectFill];
    if (error == nil) {
        LCCKMessage *message = [[LCCKMessage alloc] initWithPhoto:representationImage
                                                   thumbnailPhoto:thumbnailPhoto
                                                        photoPath:path
                                                     thumbnailURL:nil
                                                   originPhotoURL:nil
                                                         senderId:self.userId
                                                           sender:self.user
                                                        timestamp:LCCK_CURRENT_TIMESTAMP
                                                  serverMessageId:nil
                                ];
        [self makeSureSendValidMessage:message afterFetchedConversationShouldWithAssert:NO];
        [self.chatViewModel sendMessage:message];
    } else {
        [self alert:@"write image to file error"];
    }
}

- (void)sendVoiceMessageWithPath:(NSString *)voicePath time:(NSTimeInterval)recordingSeconds {
    
    LCCKMessage *message = [[LCCKMessage alloc] initWithVoicePath:voicePath
                                                         voiceURL:nil
                                                    voiceDuration:[NSString stringWithFormat:@"%@", @(recordingSeconds)]
                                                         senderId:self.userId
                                                           sender:self.user
                                                        timestamp:LCCK_CURRENT_TIMESTAMP
                                                  serverMessageId:nil];
    [self makeSureSendValidMessage:message afterFetchedConversationShouldWithAssert:NO];
    [self.chatViewModel sendMessage:message];
}

- (void)sendLocationMessageWithLocationCoordinate:(CLLocationCoordinate2D)locationCoordinate locatioTitle:(NSString *)locationTitle {
    
    LCCKMessage *message = [[LCCKMessage alloc] initWithLocalPositionPhoto:({
        NSString *imageName = @"message_sender_location";
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
        image;})
                                                              geolocations:locationTitle
                                                                  location:[[CLLocation alloc] initWithLatitude:locationCoordinate.latitude
                                                                                                      longitude:locationCoordinate.longitude]
                                                                  senderId:self.userId
                                                                    sender:self.user
                                                                 timestamp:LCCK_CURRENT_TIMESTAMP
                                                           serverMessageId:nil];
    [self makeSureSendValidMessage:message afterFetchedConversationShouldWithAssert:NO];
    [self.chatViewModel sendMessage:message];
}

- (void)sendLocalFeedbackTextMessge:(NSString *)localFeedbackTextMessge {
    [self.chatViewModel sendLocalFeedbackTextMessge:localFeedbackTextMessge];
}

- (void)sendCustomMessage:(AVIMTypedMessage *)customMessage {
    [self makeSureSendValidMessageAfterFetchedConversation:customMessage];
    [self.chatViewModel sendCustomMessage:customMessage];
}

- (void)sendCustomMessage:(AVIMTypedMessage *)customMessage
            progressBlock:(AVProgressBlock)progressBlock
                  success:(LCCKBooleanResultBlock)success
                   failed:(LCCKBooleanResultBlock)failed {
    [self makeSureSendValidMessageAfterFetchedConversation:customMessage];
    [self.chatViewModel sendCustomMessage:customMessage progressBlock:progressBlock success:success failed:failed];
}

- (void)sendGiftMessage:(AVIMTypedMessage *)giftMessage
          progressBlock:(AVProgressBlock)progressBlock
                success:(LCCKBooleanResultBlock)success
                 failed:(LCCKBooleanResultBlock)failed {
    [self sendCustomMessage:giftMessage progressBlock:progressBlock success:^(BOOL succeeded, NSError *error) {
        NSUInteger index = [[giftMessage.attributes valueForKey:@"LCLKGiftIndex"] integerValue];
        [self showMyPorsche918WithImageName:giftMessage.text index:(index - 1)];
        !success ?: success(succeeded ,error);
    } failed:failed];
}

- (void)makeSureSendValidMessageAfterFetchedConversation:(id)message {
    [self makeSureSendValidMessage:message afterFetchedConversationShouldWithAssert:YES];
}

- (void)makeSureSendValidMessage:(id)message afterFetchedConversationShouldWithAssert:(BOOL)withAssert {
    NSString *formatString = @"\n\n\
    ------ BEGIN NSException Log ---------------\n \
    class name: %@                              \n \
    ------line: %@                              \n \
    ----reason: %@                              \n \
    ------ END -------------------------------- \n\n";
    if (!self.isAvailable) {
        NSString *reason = [NSString stringWithFormat:formatString,
                            @(__PRETTY_FUNCTION__),
                            @(__LINE__),
                            @"Remember to check if `isAvailable` is ture, making sure sending message after conversation has been fetched"];
        if (!withAssert) {
            LCCKLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), reason);
            return;
        }
        NSAssert(NO, reason);
    }
    if ([message isKindOfClass:[LCCKMessage class]]) {
        return;
    }
    if ([message isKindOfClass:[AVIMTypedMessage class]]) {
        return;
    }
    if ([[message class] isSubclassOfClass:[AVIMMessage class]]) {
        NSString *reason = [NSString stringWithFormat:formatString,
                            @(__PRETTY_FUNCTION__),
                            @(__LINE__),
                            @"ChatKit only support sending AVIMTypedMessage"];
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
    }
}

#pragma mark - UI init

- (void)initBarButton {
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backBtn];
}

- (void)clearCurrentConversationInfo {
    [LCCKConversationService sharedInstance].currentConversationId = nil;
}

- (void)saveCurrentConversationInfoIfExists {
    NSString *conversationId = [self getConversationIdIfExists:nil];
    if (conversationId) {
        [LCCKConversationService sharedInstance].currentConversationId = conversationId;
    }
    
    if (_conversation) {
        [LCCKConversationService sharedInstance].currentConversation = self.conversation;
    }
}

- (void)setupNavigationItemTitleWithConversation:(AVIMConversation *)conversation {
    LCCKConversationNavigationTitleView *navigationItemTitle = [[LCCKConversationNavigationTitleView alloc] initWithConversation:conversation navigationController:self.navigationController];
    navigationItemTitle.frame = CGRectZero;
    //仅修高度,xyw值不变
    navigationItemTitle.frame = ({
        CGRect frame = navigationItemTitle.frame;
        CGFloat containerViewHeight = self.navigationController.navigationBar.frame.size.height;
        CGFloat containerViewWidth = self.navigationController.navigationBar.frame.size.width - 130;
        frame.size.width = containerViewWidth;
        frame.size.height = containerViewHeight;
        frame;
    });
    self.navigationItem.titleView = navigationItemTitle;
}

- (void)fetchConversationHandler:(AVIMConversation *)conversation {
    LCCKFetchConversationHandler fetchConversationHandler;
    do {
        if (_fetchConversationHandler) {
            fetchConversationHandler = _fetchConversationHandler;
            break;
        }
        LCCKFetchConversationHandler generalFetchConversationHandler = [LCCKConversationService sharedInstance].fetchConversationHandler;
        if (generalFetchConversationHandler) {
            fetchConversationHandler = generalFetchConversationHandler;
            break;
        }
    } while (NO);
    if (fetchConversationHandler) {
        dispatch_async(dispatch_get_main_queue(),^{
            fetchConversationHandler(conversation, self);
        });
    }
}

- (void)loadLatestMessagesHandler:(BOOL)succeeded error:(NSError *)error {
    LCCKLoadLatestMessagesHandler loadLatestMessagesHandler;
    do {
        if (_loadLatestMessagesHandler) {
            loadLatestMessagesHandler = _loadLatestMessagesHandler;
            break;
        }
        LCCKLoadLatestMessagesHandler generalLoadLatestMessagesHandler = [LCCKConversationService sharedInstance].loadLatestMessagesHandler;
        if (generalLoadLatestMessagesHandler) {
            loadLatestMessagesHandler = generalLoadLatestMessagesHandler;
            break;
        }
    } while (NO);
    if (loadLatestMessagesHandler) {
        dispatch_async(dispatch_get_main_queue(),^{
            loadLatestMessagesHandler(self, succeeded, error);
        });
    }
}

- (void)refreshConversation:(AVIMConversation *)conversation isJoined:(BOOL)isJoined {
    [self refreshConversation:conversation isJoined:isJoined error:nil];
}

- (NSString *)getConversationIdIfExists:(AVIMConversation *)conversation {
    NSString *conversationId;
    do {
        if (self.conversationId) {
            conversationId = self.conversationId;
            break;
        }
        if (_conversation) {
            conversationId = self.conversation.conversationId;
            break;
        }
        if (conversation) {
            conversationId = conversation.conversationId;
            break;
        }
    } while (NO);
    return conversationId;
}

- (void)notJoinedHandler:(AVIMConversation *)conversation error:(NSError *)aError {
    void(^notJoinedHandler)(id<LCCKUserDelegate> user, NSError *error) = ^(id<LCCKUserDelegate> user, NSError *error) {
        LCCKConversationInvalidedHandler conversationInvalidedHandler = [[LCCKConversationService sharedInstance] conversationInvalidedHandler];
        NSString *conversationId = [self getConversationIdIfExists:conversation];
        //错误码参考：https://leancloud.cn/docs/realtime_v2.html#%E4%BA%91%E7%AB%AF%E9%94%99%E8%AF%AF%E7%A0%81%E8%AF%B4%E6%98%8E
        if (error.code == 4401 && conversationId.length > 0) {
            //如果被管理员踢出群之后，再进入该会话，本地可能有缓存，要清除掉，防止下次再次进入。
            [[LCCKConversationService sharedInstance] deleteRecentConversationWithConversationId:conversationId];
        }
        conversationInvalidedHandler(conversationId, self, user, error);
    };
    
    if (conversation && conversation.creator) {
        [[LCCKUserSystemService sharedInstance] getProfilesInBackgroundForUserIds:@[ conversation.creator ] callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
            id<LCCKUserDelegate> user;
            @try {
                user = users[0];
            } @catch (NSException *exception) {}
            !notJoinedHandler ?: notJoinedHandler(user, aError);
        }];
    } else {
        !notJoinedHandler ?: notJoinedHandler(nil, aError);
    }
}

/*!
 * conversation 不一定有值，可能为 nil
 */
- (void)refreshConversation:(AVIMConversation *)aConversation isJoined:(BOOL)isJoined error:(NSError *)error {
    if (error) {
        [self notJoinedHandler:aConversation error:error];
        aConversation = nil;
    }
    
    AVIMConversation *conversation;
    if (isJoined && !error) {
        conversation = aConversation;
    }
    _conversation = conversation;
    [self saveCurrentConversationInfoIfExists];
    [self callbackCurrentConversationEvenNotExists:conversation callback:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self handleLoadHistoryMessagesHandlerIfIsJoined:isJoined];
        }
    }];
}

- (void)callbackCurrentConversationEvenNotExists:(AVIMConversation *)conversation callback:(LCCKBooleanResultBlock)callback {
    if (conversation.createAt) {
        if (!conversation.imClient) {
            [conversation setValue:[LCCKSessionService sharedInstance].client forKey:@"imClient"];
            LCCKLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"imClient is nil");
        }
        BOOL hasDraft = (conversation.lcck_draft.length > 0);
        if (hasDraft) {
            [self loadDraft];
        }
        self.conversationId = conversation.conversationId;
        [self.chatViewModel resetBackgroundImage];
        //系统对话
        if (conversation.members.count == 0) {
            self.navigationItem.title = conversation.lcck_title;
            [self fetchConversationHandler:conversation];
            !callback ?: callback(YES, nil);
            return;
        }
        [[LCChatKit sharedInstance] getProfilesInBackgroundForUserIds:conversation.members callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
            if (!self.disableTitleAutoConfig && (users.count > 0)) {
                [self setupNavigationItemTitleWithConversation:conversation];
            }
            [self fetchConversationHandler:conversation];
            !callback ?: callback(YES, nil);
        }];
    } else {
        [self fetchConversationHandler:conversation];
        NSInteger code = 0;
        NSString *errorReasonText = @"error reason";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                             code:code
                                         userInfo:errorInfo];
        
        !callback ?: callback(NO, error);
    }
}

- (BOOL)isAvailable {
    BOOL isAvailable = self.conversation;
    return isAvailable;
}

//TODO:Conversation为nil,不callback
- (void)handleLoadHistoryMessagesHandlerIfIsJoined:(BOOL)isJoined {
    if (!isJoined) {
        BOOL succeeded = NO;
        //错误码参考：https://leancloud.cn/docs/realtime_v2.html#服务器端错误码说明
        NSInteger code = 4312;
        NSString *errorReasonText = @"拉取对话消息记录被拒绝，当前用户不再对话中";
        NSDictionary *errorInfo = @{
                                    @"code" : @(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKConversationViewControllerErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        [self loadLatestMessagesHandler:succeeded error:error];
        return;
    }
    __weak __typeof(self) weakSelf = self;
    [self.chatViewModel loadMessagesFirstTimeWithCallback:^(BOOL succeeded, id object, NSError *error) {
        dispatch_async(dispatch_get_main_queue(),^{
            [weakSelf loadLatestMessagesHandler:succeeded error:error];
            BOOL isFirstTimeMeet = (([object count] == 0) && succeeded);
            [self sendWelcomeMessageIfNeeded:isFirstTimeMeet];
        });
    }];
}

- (void)sendWelcomeMessageIfNeeded:(BOOL)isFirstTimeMeet {
    //系统对话
    if (_conversation.members.count == 0) {
        return;
    }
    __block NSString *welcomeMessage;
    LCCKConversationType conversationType = _conversation.lcck_type;
    switch (conversationType) {
        case LCCKConversationTypeSingle:
            welcomeMessage = LCCKLocalizedStrings(@"SingleWelcomeMessage");
            break;
        case LCCKConversationTypeGroup:
            welcomeMessage = LCCKLocalizedStrings(@"GroupWelcomeMessage");
            break;
        default:
            break;
    }
    BOOL isAllowInUserSetting = ([welcomeMessage length] > 0);
    if (!isAllowInUserSetting) {
        return;
    }
    BOOL isSessionAvailable = [LCCKSessionService sharedInstance].connect;
    BOOL isNeverChat = (isSessionAvailable && isFirstTimeMeet);
    BOOL shouldSendWelcome = self.isFirstTimeJoinGroup || isNeverChat;
    if (shouldSendWelcome) {
        [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserDelegate> user, NSError *error) {
            NSString *userName = user.name;
            //            if (userName.length > 0 && (conversationType == LCCKConversationTypeGroup)) {
            //                welcomeMessage = [NSString stringWithFormat:@"%@%@", LCCKLocalizedStrings(@"GroupWelcomeMessageWithNickName"), userName];
            //            }
            [self sendTextMessage:welcomeMessage];
        }];
    }
}

- (NSString *)userId {
    return [LCChatKit sharedInstance].clientId;
}

#pragma mark - LCCKChatBarDelegate

- (void)chatBar:(LCCKChatBar *)chatBar sendMessage:(NSString *)message {
    [self sendTextMessage:message];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendVoice:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds{
    [self sendVoiceMessageWithPath:voiceFileName time:seconds];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendPictures:(NSArray<UIImage *> *)pictures{
    [self sendImages:pictures];
}

- (void)didInputAtSign:(LCCKChatBar *)chatBar {
    //系统对话
    if (_conversation.members.count == 0) {
        return;
    }
    if (self.conversation.lcck_type == LCCKConversationTypeGroup) {
        [self presentSelectMemberViewController];
    }
}

- (void)presentSelectMemberViewController {
    NSString *cuttentClientId = [LCCKSessionService sharedInstance].clientId;
    NSArray<id<LCCKUserDelegate>> *users = [[LCCKUserSystemService sharedInstance] getCachedProfilesIfExists:self.conversation.members shouldSameCount:YES error:nil];
    LCCKContactListViewController *contactListViewController = [[LCCKContactListViewController alloc] initWithContacts:[NSSet setWithArray:users] userIds:[NSSet setWithArray:self.conversation.members] excludedUserIds:[NSSet setWithArray:@[cuttentClientId]] mode:LCCKContactListModeMultipleSelection];
    [contactListViewController setViewDidDismissBlock:^(LCCKBaseViewController *viewController) {
        [self.chatBar open];
        [self.chatBar beginInputing];
    }];
    [contactListViewController setSelectedContactCallback:^(UIViewController *viewController, NSString *peerId) {
        [viewController dismissViewControllerAnimated:YES completion:^{
            [self.chatBar open];
        }];
        if (peerId.length > 0) {
            NSArray *peerNames = [[LCChatKit sharedInstance] getCachedProfilesIfExists:@[peerId] error:nil];
            NSString *peerName;
            @try {
                id<LCCKUserDelegate> user = peerNames[0];
                peerName = user.name ?: user.clientId;
            } @catch (NSException *exception) {
                peerName = peerId;
            }
            peerName = [NSString stringWithFormat:@"@%@ ", peerName];
            [self.chatBar appendString:peerName];
        }
    }];
    [contactListViewController setSelectedContactsCallback:^(UIViewController *viewController, NSArray<NSString *> *peerIds) {
        if (peerIds.count > 0) {
            NSArray<id<LCCKUserDelegate>> *peers = [[LCCKUserSystemService sharedInstance] getCachedProfilesIfExists:peerIds error:nil];
            NSMutableArray *peerNames = [NSMutableArray arrayWithCapacity:peers.count];
            [peers enumerateObjectsUsingBlock:^(id<LCCKUserDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.name) {
                    [peerNames addObject:obj.name];
                } else {
                    [peerNames addObject:obj.clientId];
                }
            }];
            NSArray *realPeerNames;
            if (peerNames.count > 0) {
                realPeerNames = peerNames;
            } else {
                realPeerNames = peerIds;
            }
            NSString *peerName = [[realPeerNames valueForKey:@"description"] componentsJoinedByString:@" @"];
            peerName = [NSString stringWithFormat:@"@%@ ", peerName];
            [self.chatBar appendString:peerName];
        }
    }];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:contactListViewController];
    [self presentViewController:navigationController animated:YES completion:^{
        [self.chatBar close];
    }];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendLocation:(CLLocationCoordinate2D)locationCoordinate locationText:(NSString *)locationText {
    [self sendLocationMessageWithLocationCoordinate:locationCoordinate locatioTitle:locationText];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendLikeMessageCount:(NSUInteger)likeMessageCount {
    //TODO:点赞冷却
    [self sendLikeMessage];
}

- (void)sendLikeMessage {
    LCLKLiveLikeMessage *likeMessage = [[LCLKLiveLikeMessage alloc] init];
    [self sendCustomMessage:likeMessage progressBlock:nil success:^(BOOL succeeded, NSError *error) {
        //        [self showTheLove:self.heartBtn];
        
        // button点击动画
        CAKeyframeAnimation *btnAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        btnAnimation.values = @[@(1.0),@(0.7),@(0.5),@(0.3),@(0.5),@(0.7),@(1.0), @(1.2), @(1.4), @(1.2), @(1.0)];
        btnAnimation.keyTimes = @[@(0.0),@(0.1),@(0.2),@(0.3),@(0.4),@(0.5),@(0.6),@(0.7),@(0.8),@(0.9),@(1.0)];
        btnAnimation.calculationMode = kCAAnimationLinear;
        btnAnimation.duration = 0.3;
        [self.applauseButton.layer addAnimation:btnAnimation forKey:@"SHOW"];
        [self applauseButtonClick];
    } failed:^(BOOL succeeded, NSError *error) {
        //TODO:点赞失败
    }];
}

- (void)applauseButtonClick {
    
    self.applauseNumber++;
    self.applauseNumberLabel.text = [NSString stringWithFormat:@"%zd",self.applauseNumber];
   
    [self showTheApplauseInView:self.view belowView:self.applauseButton];
}

//鼓掌动画
- (void)showTheApplauseInView:(UIView *)view belowView:(UIButton *)v{
    NSInteger index = arc4random_uniform(24); //取随机图片
    NSString *image = [NSString stringWithFormat:@"applause_%zd",index];
    UIImageView *applauseView = [[UIImageView alloc]initWithFrame:CGRectMake(self.applauseButton.frame.origin.x, self.applauseButton.frame.origin.y, 40, 40)];//增大y值可隐藏弹出动画
    [view insertSubview:applauseView belowSubview:v];
    applauseView.image = [UIImage imageNamed:image];
    
    CGFloat AnimH = 350; //动画路径高度,
    applauseView.transform = CGAffineTransformMakeScale(0, 0);
    applauseView.alpha = 0;
    
    //弹出动画
    [UIView animateWithDuration:0.2 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
        applauseView.transform = CGAffineTransformIdentity;
        applauseView.alpha = 0.9;
    } completion:NULL];
    
    //随机偏转角度
    NSInteger i = arc4random_uniform(2);
    NSInteger rotationDirection = 1- (2*i);// -1 OR 1,随机方向
    NSInteger rotationFraction = arc4random_uniform(10); //随机角度
    //图片在上升过程中旋转
    [UIView animateWithDuration:4 animations:^{
        applauseView.transform = CGAffineTransformMakeRotation(rotationDirection * M_PI/(4 + rotationFraction*0.2));
    } completion:NULL];
    
    //动画路径
    UIBezierPath *heartTravelPath = [UIBezierPath bezierPath];
    [heartTravelPath moveToPoint:applauseView.center];
    
    //随机终点
    CGFloat ViewX = applauseView.center.x;
    CGFloat ViewY = applauseView.center.y;
    CGPoint endPoint = CGPointMake(ViewX + rotationDirection*10, ViewY - AnimH);
    
    //随机control点
    NSInteger j = arc4random_uniform(2);
    NSInteger travelDirection = 1- (2*j);//随机放向 -1 OR 1
    
    NSInteger m1 = ViewX + travelDirection*(arc4random_uniform(20) + 50);
    NSInteger n1 = ViewY - 60 + travelDirection*arc4random_uniform(20);
    NSInteger m2 = ViewX - travelDirection*(arc4random_uniform(20) + 50);
    NSInteger n2 = ViewY - 90 + travelDirection*arc4random_uniform(20);
    CGPoint controlPoint1 = CGPointMake(m1, n1);//control根据自己动画想要的效果做灵活的调整
    CGPoint controlPoint2 = CGPointMake(m2, n2);
    //根据贝塞尔曲线添加动画
    [heartTravelPath addCurveToPoint:endPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    
    //关键帧动画,实现整体图片位移
    CAKeyframeAnimation *keyFrameAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    keyFrameAnimation.path = heartTravelPath.CGPath;
    keyFrameAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    keyFrameAnimation.duration = 3 ;//往上飘动画时长,可控制速度
    [applauseView.layer addAnimation:keyFrameAnimation forKey:@"positionOnPath"];
    
    //消失动画
    [UIView animateWithDuration:3 animations:^{
        applauseView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [applauseView removeFromSuperview];
    }];
}

//// 点赞
//- (void)showTheLove:(UIButton *)sender {
//    _heartSize = 36;
//
//    DMHeartFlyView *heart = [[DMHeartFlyView alloc]initWithFrame:CGRectMake(0, 0, _heartSize, _heartSize)];
//    [self.view addSubview:heart];
//    CGPoint fountainSource = self.heartBtn.center;//CGPointMake(_heartSize + _heartSize/2.0, self.view.bounds.size.height - _heartSize/2.0 - 10);
//    heart.center = fountainSource;
//    [heart animateInView:self.view];
//
//    // button点击动画
//    CAKeyframeAnimation *btnAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
//    btnAnimation.values = @[@(1.0),@(0.7),@(0.5),@(0.3),@(0.5),@(0.7),@(1.0), @(1.2), @(1.4), @(1.2), @(1.0)];
//    btnAnimation.keyTimes = @[@(0.0),@(0.1),@(0.2),@(0.3),@(0.4),@(0.5),@(0.6),@(0.7),@(0.8),@(0.9),@(1.0)];
//    btnAnimation.calculationMode = kCAAnimationLinear;
//    btnAnimation.duration = 0.3;
//    [sender.layer addAnimation:btnAnimation forKey:@"SHOW"];
//}


/**
 *  lazy load applauseButton
 *
 *  @return UIButton
 */
- (UIButton *)applauseButton {
    if (_applauseButton == nil) {
        UIButton *applauseButton = [[UIButton alloc] init];
        applauseButton = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width-15-60, self.view.frame.size.height-80-60, 60, 60)];
        applauseButton.contentMode = UIViewContentModeScaleToFill;
        [applauseButton setImage:[UIImage imageNamed:@"applause"] forState:UIControlStateNormal];
        [applauseButton setImage:[UIImage imageNamed:@"applause"] forState:UIControlStateHighlighted];
        [applauseButton addTarget:self action:@selector(sendLikeMessage) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:applauseButton];
        [applauseButton addSubview:self.applauseNumberLabel];
        _applauseButton = applauseButton;
    }
    return _applauseButton;
}

/**
 *  lazy load applauseNumberLabel
 *
 *  @return UILabel
 */
- (UILabel *)applauseNumberLabel {
    if (_applauseNumberLabel == nil) {
        UILabel *applauseNumberLabel = [[UILabel alloc] init];
        //鼓掌数
        applauseNumberLabel = [[UILabel alloc]init];
        applauseNumberLabel.textColor = [UIColor whiteColor];
        applauseNumberLabel.font = [UIFont systemFontOfSize:12];
        applauseNumberLabel.text = @"0";
        applauseNumberLabel.textAlignment = NSTextAlignmentCenter;
        applauseNumberLabel.frame = CGRectMake(6, 43, 50, 12);
        _applauseNumberLabel = applauseNumberLabel;
    }
    return _applauseNumberLabel;
}

- (void)chatBarFrameDidChange:(LCCKChatBar *)chatBar shouldScrollToBottom:(BOOL)shouldScrollToBottom {
    [UIView animateWithDuration:LCCKAnimateDuration animations:^{
        [self.tableView layoutIfNeeded];
        self.allowScrollToBottom = shouldScrollToBottom;
        [self scrollToBottomAnimated:NO];
    } completion:nil];
}

#pragma mark - LCCKChatMessageCellDelegate

- (void)messageCellTappedHead:(LCCKChatMessageCell *)messageCell {
    LCCKOpenProfileBlock openProfileBlock = [LCCKUIService sharedInstance].openProfileBlock;
    !openProfileBlock ?: openProfileBlock(messageCell.message.senderId, messageCell.message.sender, self);
}

- (void)messageCellTappedBlank:(LCCKChatMessageCell *)messageCell {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

- (void)messageCellTappedMessage:(LCCKChatMessageCell *)messageCell {
    if (!messageCell) {
        return;
    }
    [self.chatBar close];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:messageCell];
    LCCKMessage *message = [self.chatViewModel.dataArray lcck_messageAtIndex:indexPath.row];
    switch (messageCell.mediaType) {
        case kAVIMMessageMediaTypeAudio: {
            NSString *voiceFileName = message.voicePath;//必须带后缀，.mp3；
            [[LCCKAVAudioPlayer sharePlayer] playAudioWithURLString:voiceFileName identifier:message.messageId];
        }
            break;
        case kAVIMMessageMediaTypeImage: {
            ///FIXME:4S等低端机型在图片超过1M时，有几率会Crash，尤其是全景图。
            LCCKPreviewImageMessageBlock previewImageMessageBlock = [LCCKUIService sharedInstance].previewImageMessageBlock;
            UIImageView *placeholderView = [(LCCKChatImageMessageCell *)messageCell messageImageView];
            NSDictionary *userInfo = @{
                                       /// 传递触发的UIViewController对象
                                       LCCKPreviewImageMessageUserInfoKeyFromController : self,
                                       /// 传递触发的UIView对象
                                       LCCKPreviewImageMessageUserInfoKeyFromView : self.tableView,
                                       LCCKPreviewImageMessageUserInfoKeyFromPlaceholderView : placeholderView
                                       };
            NSArray *allVisibleImages = nil;
            NSArray *allVisibleThumbs = nil;
            NSNumber *selectedMessageIndex = nil;
            [self.chatViewModel getAllVisibleImagesForSelectedMessage:messageCell.message allVisibleImages:&allVisibleImages allVisibleThumbs:&allVisibleThumbs selectedMessageIndex:&selectedMessageIndex];
            
            if (previewImageMessageBlock) {
                previewImageMessageBlock(selectedMessageIndex.unsignedIntegerValue, allVisibleImages, allVisibleThumbs, userInfo);
            } else {
                [self previewImageMessageWithInitialIndex:selectedMessageIndex.unsignedIntegerValue allVisibleImages:allVisibleImages allVisibleThumbs:allVisibleThumbs placeholderImageView:placeholderView fromViewController:self];
            }
        }
            break;
        case kAVIMMessageMediaTypeLocation: {
            NSDictionary *userInfo = @{
                                       /// 传递触发的UIViewController对象
                                       LCCKPreviewLocationMessageUserInfoKeyFromController : self,
                                       /// 传递触发的UIView对象
                                       LCCKPreviewLocationMessageUserInfoKeyFromView : self.tableView,
                                       };
            LCCKPreviewLocationMessageBlock previewLocationMessageBlock = [LCCKUIService sharedInstance].previewLocationMessageBlock;
            !previewLocationMessageBlock ?: previewLocationMessageBlock(message.location, message.geolocations, userInfo);
        }
            break;
        default: {
            //TODO:自定义消息的点击事件
            NSString *formatString = @"\n\n\
            ------ BEGIN NSException Log ---------------\n \
            class name: %@                              \n \
            ------line: %@                              \n \
            ----reason: %@                              \n \
            ------ END -------------------------------- \n\n";
            NSString *reason = [NSString stringWithFormat:formatString,
                                @(__PRETTY_FUNCTION__),
                                @(__LINE__),
                                @"messageCell.messageType not handled"];
            //手动创建一个异常导致的崩溃事件 http://is.gd/EfVfN0
            @throw [NSException exceptionWithName:NSGenericException
                                           reason:reason
                                         userInfo:nil];
        }
            break;
    }
    [self.chatBar open];
}

- (void)previewImageMessageWithInitialIndex:(NSUInteger)initialIndex
                           allVisibleImages:(NSArray *)allVisibleImages
                           allVisibleThumbs:(NSArray *)allVisibleThumbs
                       placeholderImageView:(UIImageView *)placeholderImageView
                         fromViewController:(LCCKConversationViewController *)fromViewController{
    // Browser
    NSMutableArray *photos = [[NSMutableArray alloc] initWithCapacity:[allVisibleImages count]];
    NSMutableArray *thumbs = [[NSMutableArray alloc] initWithCapacity:[allVisibleThumbs count]];
    LCCKPhoto *photo;
    for (NSUInteger index = 0; index < allVisibleImages.count; index++) {
        id image_ = allVisibleImages[index];
        
        if ([image_ isKindOfClass:[UIImage class]]) {
            photo = [LCCKPhoto photoWithImage:image_];
        } else {
            photo = [LCCKPhoto photoWithURL:image_];
        }
        if (index == initialIndex) {
            photo.placeholderImageView = placeholderImageView;
        }
        [photos addObject:photo];
    }
    // Options
    self.photos = photos;
    self.thumbs = thumbs;
    // Create browser
    LCCKPhotoBrowser *browser = [[LCCKPhotoBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    [browser setInitialPageIndex:initialIndex];
    browser.usePopAnimation = YES;
    browser.animationDuration = 0.15;
    // Show
    [fromViewController presentViewController:browser animated:YES completion:nil];
}

- (void)avatarImageViewLongPressed:(LCCKChatMessageCell *)messageCell {
    if (messageCell.message.senderId == [LCChatKit sharedInstance].clientId || self.conversation.lcck_type == LCCKConversationTypeSingle) {
        return;
    }
    NSString *userName = messageCell.message.localDisplayName;
    if (userName.length == 0 || !userName || [userName isEqualToString:LCCKLocalizedStrings(@"nickNameIsNil")]) {
        return;
    }
    NSString *appendString = [NSString stringWithFormat:@"@%@ ", userName];
    [self.chatBar appendString:appendString];
}

- (void)textMessageCellDoubleTapped:(LCCKChatMessageCell *)messageCell {
    if (self.disableTextShowInFullScreen) {
        return;
    }
    LCCKTextFullScreenViewController *textFullScreenViewController = [[LCCKTextFullScreenViewController alloc] initWithText:messageCell.message.text];
    [self.navigationController pushViewController:textFullScreenViewController animated:NO];
}

- (void)resendMessage:(LCCKChatMessageCell *)messageCell {
    [self.chatViewModel resendMessageForMessageCell:messageCell];
}

- (void)fileMessageDidDownload:(LCCKChatMessageCell *)messageCell {
    [self reloadAfterReceiveMessage];
}

- (void)messageCell:(LCCKChatMessageCell *)messageCell didTapLinkText:(NSString *)linkText linkType:(MLLinkType)linkType {
    switch (linkType) {
        case MLLinkTypeURL: {
            LCCKWebViewController *webViewController = [[LCCKWebViewController alloc] init];
            webViewController.URL = [NSURL URLWithString:linkText];
            LCCKSafariActivity *activity = [[LCCKSafariActivity alloc] init];
            webViewController.applicationActivities = @[activity];
            webViewController.excludedActivityTypes = @[UIActivityTypeMail, UIActivityTypeMessage, UIActivityTypePostToWeibo];
            [self.navigationController pushViewController:webViewController animated:YES];
        }
            break;
        case MLLinkTypePhoneNumber: {
            NSString *title = [NSString stringWithFormat:@"%@?", LCCKLocalizedStrings(@"call")];
            LCCKAlertController *alert = [LCCKAlertController alertControllerWithTitle:title
                                                                               message:@""
                                                                        preferredStyle:LCCKAlertControllerStyleAlert];
            NSString *cancelActionTitle = LCCKLocalizedStrings(@"cancel");
            LCCKAlertAction* cancelAction = [LCCKAlertAction actionWithTitle:cancelActionTitle style:LCCKAlertActionStyleDefault
                                                                     handler:^(LCCKAlertAction * action) {}];
            [alert addAction:cancelAction];
            NSString *resendActionTitle = LCCKLocalizedStrings(@"call");
            LCCKAlertAction* resendAction = [LCCKAlertAction actionWithTitle:resendActionTitle style:LCCKAlertActionStyleDefault
                                                                     handler:^(LCCKAlertAction * action) {
                                                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat: @"tel:%@", linkText]]];
                                                                     }];
            [alert addAction:resendAction];
            [alert showWithSender:nil controller:self animated:YES completion:NULL];
        }
            break;
        default:
            break;
    }
}

#pragma mark - LCCKConversationViewModelDelegate

- (void)messageReadStateChanged:(LCCKMessageReadState)readState withProgress:(CGFloat)progress forIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    LCCKChatMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (![self.tableView.visibleCells containsObject:messageCell]) {
        return;
    }
    messageCell.messageReadState = readState;
}

- (void)messageSendStateChanged:(LCCKMessageSendState)sendState withProgress:(CGFloat)progress forIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    LCCKChatMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (![self.tableView.visibleCells containsObject:messageCell]) {
        return;
    }
    if (messageCell.mediaType == kAVIMMessageMediaTypeImage) {
        [(LCCKChatImageMessageCell *)messageCell setUploadProgress:progress];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        messageCell.messageSendState = sendState;
    });
}

- (void)reloadAfterReceiveMessage {
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

#pragma mark - LCCKAVAudioPlayerDelegate

- (void)loadMoreMessagesScrollTotop {
    [self.chatViewModel loadOldMessages];
}

- (void)updateStatusView {
    BOOL isConnected = [LCCKSessionService sharedInstance].connect;
    if (isConnected) {
        self.clientStatusView.hidden = YES;
    } else {
        self.clientStatusView.hidden = NO;
    }
}


#pragma mark -
#pragma mark - Gift Sended Or Received Method

- (void)showMyPorsche918WithImageName:(NSString *)imageName index:(NSUInteger)index {
    NSUInteger itemType = index;
    //    [self sendBarrageText:text];
    //    [self showMyPorsche918];
    CGRect fromRect;
    CGRect endRect;
    if (itemType < 4) {
        fromRect = CGRectMake(0, 0, 0, 0);
        endRect = CGRectMake([UIScreen mainScreen].bounds.size.width * 0.5 - 100, [UIScreen mainScreen].bounds.size.height * 0.5 - 100 * 0.5, 240, 120);
    } else {
        fromRect = CGRectMake([UIScreen mainScreen].bounds.size.width, 0, 0, 0);
        endRect = CGRectMake(0, [UIScreen mainScreen].bounds.size.height * 0.5 - 100 * 0.5, 240, 120);
    }
    [self showMyPorsche918WithImageName:imageName fromRect:fromRect endRect:endRect];
}

//送礼物
- (void)showMyPorsche918WithImageName:(NSString *)imageName fromRect:(CGRect)fromRect endRect:(CGRect)endRect {
    CGFloat durTime = 3.0;
    
    //    UIImageView *gifImageView = [[UIImageView alloc] initWithFrame:frame];
    
    UIImageView *porsche918 = [[UIImageView alloc] init];
    [porsche918 sd_setImageWithURL:nil placeholderImage:[UIImage imageNamed:imageName]];
    
    
    //设置汽车初始位置
    porsche918.frame = fromRect;
    [self.view addSubview:porsche918];
    
    //给汽车添加动画
    [UIView animateWithDuration:durTime animations:^{
        
        porsche918.frame = endRect;
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(durTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //
        [UIView animateWithDuration:0.5 animations:^{
            porsche918.alpha = 0;
        } completion:^(BOOL finished) {
            [porsche918 removeFromSuperview];
        }];
    });
    
    //烟花
    CALayer *fireworksL = [CALayer layer];
    fireworksL.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 250) * 0.5, 100, 250, 50);
    fireworksL.contents = (id)[UIImage imageNamed:@"gift_fireworks_0"].CGImage;
    [self.view.layer addSublayer:fireworksL];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(durTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            //没找到设置透明度的方法，有创意可以自己写
            //            fireworksL.alpha = 0;
        } completion:^(BOOL finished) {
            [fireworksL removeFromSuperlayer];
        }];
    });
    _fireworksL = fireworksL;
    
    
    
    NSMutableArray *tempArray = [NSMutableArray array];
    
    for (int i = 1; i < 3; i++) {
        
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"gift_fireworks_%d",i]];
        [tempArray addObject:image];
    }
    _fireworksArray = tempArray;
    
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update) userInfo:nil repeats:YES];
}

static int _fishIndex = 0;

- (void)update {
    
    _fishIndex++;
    
    if (_fishIndex > 1) {
        _fishIndex = 0;
    }
    UIImage *image = self.fireworksArray[_fishIndex];
    _fireworksL.contents = (id)image.CGImage;
}

@end
