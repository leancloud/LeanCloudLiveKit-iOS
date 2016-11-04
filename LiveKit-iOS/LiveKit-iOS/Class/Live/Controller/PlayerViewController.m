//
//  PlayerViewController.m
//  高仿映客
//
//  Created by JIAAIR on 16/7/2.
//  Copyright © 2016年 JIAAIR. All rights reserved.
//

#import "PlayerViewController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
//#import "DMHeartFlyView.h"
#import <Accelerate/Accelerate.h>
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
#import <ChatKit/LCCKChatBar.h>
#import "LCCKUtil.h"
#import "NSObject+LCCKHUD.h" 
#import "LCChatKitExample.h"
#import "Masonry.h"
#import "LCCKChatMoreView.h"
#import "LCLKConstants.h"

#define XJScreenH [UIScreen mainScreen].bounds.size.height
#define XJScreenW [UIScreen mainScreen].bounds.size.width
@interface PlayerViewController ()

@property (atomic, retain) id <IJKMediaPlayback> player;

@property (weak, nonatomic) UIView *PlayerView;

@property (atomic, strong) NSURL *url;

@property (nonatomic, assign)int number;

@property (nonatomic, assign)CGFloat heartSize;

@property (nonatomic, strong)UIImageView *dimIamge;

@property (nonatomic, strong) NSArray *fireworksArray;

@property (nonatomic, weak) CALayer *fireworksL;

@property (nonatomic, strong) LCCKConversationViewController *conversationViewController;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation PlayerViewController

- (LCCKConversationViewController *)exampleOpenConversationViewControllerWithConversaionId:(NSString *)conversationId
                                                                  fromNavigationController:(UINavigationController *)aNavigationController {
    LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithConversationId:conversationId];
    [conversationViewController setViewDidLoadBlock:^(LCCKBaseViewController *viewController) {
        LCCKConversationViewController *conversationViewController_ = (LCCKConversationViewController *)viewController;
        conversationViewController_.view.backgroundColor = [UIColor clearColor];
        conversationViewController_.tableView.backgroundColor = [UIColor clearColor];
    }];
    [conversationViewController setViewWillAppearBlock:^(LCCKBaseViewController *viewController, BOOL aAnimated) {
        LCCKConversationViewController *conversationViewController_ = (LCCKConversationViewController *)viewController;
        conversationViewController_.view.backgroundColor = [UIColor clearColor];
        conversationViewController_.tableView.backgroundColor = [UIColor clearColor];
    }];
    conversationViewController.enableAutoJoin = YES;
    [conversationViewController setViewWillDisappearBlock:^(LCCKBaseViewController *viewController, BOOL aAnimated) {
        [[self class] lcck_hideHUDForView:viewController.view];
    }];
    _conversationViewController = conversationViewController;
    return conversationViewController;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]  removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];
 

//    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(autoSendBarrage) userInfo:nil repeats:YES];
       // 播放视频
    [self goPlaying];
    
    // 开启通知
    [self installMovieNotificationObservers];
    
    // 设置加载视图
    [self setupLoadingView];
    
    //TODO: 查询或创建对话，根据 self.url进行查询
//    self.liveUrl;
    
    [[LCLKLiveService sharedInstance] fetchConversationIfNeededForLiveId:self.liveUrl callback:^(AVIMConversation *conversation, NSError *error) {
        if (conversation) {
            LCCKConversationViewController *conversationViewController = [self exampleOpenConversationViewControllerWithConversaionId:conversation.conversationId fromNavigationController:nil];
            [self displayContentController:conversationViewController];
            [self.view addSubview:conversationViewController.renderer.view];
        }
        
    }];
   

//    [[[LCChatKit sharedInstance] client] createConversationWithName:<#(NSString *)#> clientIds:<#(NSArray *)#> callback:<#^(AVIMConversation *conversation, NSError *error)callback#>];

    [self setupBtn];
//    conversationViewController.chatBar.moreView.delegate = self;
//    conversationViewController.chatBar.moreView.dataSource = self;


}

- (void)displayContentController:(UIViewController *)content; {
    [self addChildViewController:content];                 // 1
    content.view.bounds = self.view.bounds;                 //2
    [self.view addSubview:content.view];
    [content didMoveToParentViewController:self];          // 3
}

- (void)viewWillAppear:(BOOL)animated {
    if (![self.player isPlaying]) {
        //准备播放
        [self.player prepareToPlay];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self goBack];
}

#pragma mark ---- <设置加载视图>
- (void)setupLoadingView {
    self.dimIamge = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [_dimIamge sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://img.meelive.cn/%@", _imageUrl]] placeholderImage:[UIImage imageNamed:@"default_room"]];
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = _dimIamge.bounds;
    [_dimIamge addSubview:visualEffectView];
    [self.view addSubview:_dimIamge];
}

#pragma mark ---- <创建按钮>
- (void)setupBtn {
    
    // 返回
    UIButton * backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(10, 64 / 2 - 8, 33, 33);
    [backBtn setImage:[UIImage imageNamed:@"返回"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    backBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    backBtn.layer.shadowOffset = CGSizeMake(0, 0);
    backBtn.layer.shadowOpacity = 0.5;
    backBtn.layer.shadowRadius = 1;
    [self.view addSubview:backBtn];
    
    // 暂停
    UIButton * playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    playBtn.frame = CGRectMake(XJScreenW - 33 - 10, 64 / 2 - 8, 33, 33);
    
    if (self.number == 0) {
        [playBtn setImage:[UIImage imageNamed:@"暂停"] forState:(UIControlStateNormal)];
        [playBtn setImage:[UIImage imageNamed:@"开始"] forState:(UIControlStateSelected)];
    }else{
        [playBtn setImage:[UIImage imageNamed:@"开始"] forState:(UIControlStateNormal)];
        [playBtn setImage:[UIImage imageNamed:@"暂停"] forState:(UIControlStateSelected)];
    }
    
    [playBtn addTarget:self action:@selector(play_btn:) forControlEvents:(UIControlEventTouchUpInside)];
    playBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    playBtn.layer.shadowOffset = CGSizeMake(0, 0);
    playBtn.layer.shadowOpacity = 0.5;
    playBtn.layer.shadowRadius = 1;
    [self.view addSubview:playBtn];

}

- (void)goPlaying {
    //获取url
    self.url = [NSURL URLWithString:_liveUrl];
    _player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.url withOptions:nil];
    
    UIView *playerview = [self.player view];
    UIView *displayView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    self.PlayerView = displayView;
    [self.view addSubview:self.PlayerView];
    
    // 自动调整自己的宽度和高度
    playerview.frame = self.PlayerView.bounds;
    playerview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.PlayerView insertSubview:playerview atIndex:1];
    [playerview addSubview:self.conversationViewController.renderer.view];
    [_player setScalingMode:IJKMPMovieScalingModeAspectFill];
}

// 返回
- (void)goBack {
    // 停播
    [self.player shutdown];
    [self.navigationController popViewControllerAnimated:true];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

// 暂停开始
- (void)play_btn:(UIButton *)sender {
    
    sender.selected =! sender.selected;
    if (![self.player isPlaying]) {
        // 播放
        [self.player play];
    }else{
        // 暂停
        [self.player pause];
    }
}

#pragma Install Notifiacation
- (void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
    
}

- (void)removeMovieNotificationObservers {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                                  object:_player];
}

#pragma Selector func

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"LoadStateDidChange: IJKMovieLoadStatePlayThroughOK: %d\n",(int)loadState);
    }else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackFinish:(NSNotification*)notification {
    int reason =[[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    NSLog(@"mediaIsPrepareToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    
    _dimIamge.hidden = YES;
    
    switch (_player.playbackState) {
            
        case IJKMPMoviePlaybackStateStopped:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePlaying:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStatePaused:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateInterrupted:
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
            
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
            
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

@end
