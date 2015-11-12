//
//  QWCVideoPlayerPlayerView.h
//  QWCVideoPlayerViewControllerDemo
//
//  Created by qinwei on 15/11/10.
//  Copyright © 2015年 tangqinwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QWCVideoPlayerPlayerView : UIView

@property (nonatomic,strong) AVPlayer *player;

@property (nonatomic,strong) NSString *videoGravity; /**< 视频填充样式 */

@end
