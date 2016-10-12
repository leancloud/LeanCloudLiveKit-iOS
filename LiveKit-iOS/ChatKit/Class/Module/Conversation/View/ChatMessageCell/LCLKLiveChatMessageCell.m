//
//  LCLKLiveChatMessageCell.m
//  Pods
//
//  Created by 陈宜龙 on 16/9/5.
//
//

#import "LCLKLiveChatMessageCell.h"
#import "LCCKBubbleImageFactory.h"
#import "LCCKFaceManager.h"
@interface LCLKLiveChatMessageCell ()

@property (nonatomic, strong) UILabel *messageTextLabel;

@property (nonatomic, strong) UIImageView *liveMessageContentBackgroundImageView;
@property (nonatomic, copy) NSDictionary *liveChatMessageStyle;

@end

@implementation LCLKLiveChatMessageCell
#pragma mark -
#pragma mark - LCCKChatMessageCellSubclassing Method

+ (void)load {
    [self registerCustomMessageCell];
}

+ (AVIMMessageMediaType)classMediaType {
    return LCLKMessageTypeTransient;
}

#pragma mark - Public Methods
- (void)updateConstraints {
    [super updateConstraints];
    [self.liveMessageContentBackgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        static CGFloat const LCCK_MSG_CELL_EDGES_OFFSET = 6;
        //        make.edges.equalTo(self.contentView);
        make.left.equalTo(self.contentView.mas_left).with.offset(LCCK_MSG_CELL_EDGES_OFFSET);
        make.top.equalTo(self.contentView.mas_top).with.offset(LCCK_MSG_CELL_EDGES_OFFSET);
        CGFloat width = [UIApplication sharedApplication].keyWindow.frame.size.width;
        CGFloat height = [UIApplication sharedApplication].keyWindow.frame.size.height;
        CGFloat widthLimit = MIN(width, height)/5 * 3.5;
        make.width.lessThanOrEqualTo(@(widthLimit)).priorityHigh();
        make.bottom.equalTo(self.contentView.mas_bottom).with.offset(-LCCK_MSG_CELL_EDGES_OFFSET);
    }];
}
- (void)setup {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.liveMessageContentBackgroundImageView];
    [self updateConstraintsIfNeeded];
    [super setup];
}

- (void)configureCellWithData:(AVIMTypedMessage *)message {
    NSString *nickName = nil;
    NSError *error = nil;
    [super configureCellWithData:message];
    NSString *senderClientId = [(AVIMTypedMessage *)message clientId] ?: [LCCKSessionService sharedInstance].clientId;
    //TODO:如果我正在群里聊天，这时有人进入群聊，需要异步获取头像等信息，模仿ConversationList的做法。
    [[LCCKUserSystemService sharedInstance] getCachedProfileIfExists:senderClientId name:&nickName avatarURL:nil error:&error];
    if (!nickName)  { nickName = senderClientId; }
    nickName = [nickName stringByAppendingString:@" "];
    NSString *liveChatMessage = [nickName stringByAppendingString:message.text];
    
    NSMutableAttributedString *mutable = [LCCKFaceManager emotionStrWithString:liveChatMessage];
    [mutable addAttributes:self.liveChatMessageStyle range:NSMakeRange(0, mutable.length)];

    [mutable addAttribute: NSForegroundColorAttributeName value:Color(209, 232, 172) range:[liveChatMessage rangeOfString:nickName]];
    self.messageTextLabel.attributedText = mutable;
    
    

}

/**
 *  lazy load liveMessageContentBackgroundImageView
 *
 *  @return UIImageView
 */
- (UIImageView *)liveMessageContentBackgroundImageView {
    if (_liveMessageContentBackgroundImageView == nil) {
        UIImageView *liveMessageContentBackgroundImageView = [[UIImageView alloc] init];
        _liveMessageContentBackgroundImageView = liveMessageContentBackgroundImageView;
        _liveMessageContentBackgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
        NSString *bubbleImageName = @"btn_time_bg";
        UIImage *bublleImage = [UIImage lcck_imageNamed:bubbleImageName bundleName:@"MessageBubble" bundleForClass:[self class]];
        UIEdgeInsets bubbleImageCapInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        UIImage *stretchedImage = LCCK_STRETCH_IMAGE(bublleImage, bubbleImageCapInsets);
        [_liveMessageContentBackgroundImageView setImage:stretchedImage];
    }
    return _liveMessageContentBackgroundImageView;
}

static CGFloat const LCCKLiveChatTextSize = 12;
/**
 *  lazy load messageTextLabel
 *
 *  @return UILabel
 */
- (UILabel *)messageTextLabel {
    if (_messageTextLabel == nil) {
        UILabel *messageTextLabel = [[UILabel alloc] init];
        UIFont *defaultThemeTextMessageFont = [UIFont systemFontOfSize:LCCKLiveChatTextSize];
        messageTextLabel.font = defaultThemeTextMessageFont;//[LCCKSettingService sharedInstance].defaultThemeTextMessageFont;
        messageTextLabel.numberOfLines = 0;
        messageTextLabel.textColor = [UIColor whiteColor];
        messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.liveMessageContentBackgroundImageView addSubview:(_messageTextLabel = messageTextLabel)];
        [messageTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            CGFloat offsetTopBottom = 5;//8
            CGFloat offsetLeftRight = 5;//8
            UIEdgeInsets edgeInsets = UIEdgeInsetsMake(offsetTopBottom, offsetLeftRight, offsetTopBottom, offsetLeftRight);
            make.edges.equalTo(self.liveMessageContentBackgroundImageView).with.insets(edgeInsets);
        }];
        messageTextLabel.attributedText = [[NSAttributedString alloc] initWithString:@"到了" attributes:self.liveChatMessageStyle];
    }
    return _messageTextLabel;
}

- (NSDictionary *)liveChatMessageStyle {
    if (!_liveChatMessageStyle) {
        UIFont *font = [UIFont systemFontOfSize:LCCKLiveChatTextSize];
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.paragraphSpacing = 0.15 * font.lineHeight;
        style.hyphenationFactor = 1.0;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        style.alignment = NSTextAlignmentLeft;
        _liveChatMessageStyle = @{
                                NSFontAttributeName: font,
                                NSParagraphStyleAttributeName: style,
                                NSForegroundColorAttributeName: [UIColor whiteColor]
                                };
    }
    return _liveChatMessageStyle;
}
@end
