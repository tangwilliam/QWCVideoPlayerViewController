//
//  QWCVideoPlayerViewController.m
//  QWCVideoPlayerViewControllerDemo
//
//  Created by qinwei on 15/11/10.
//  Copyright © 2015年 tangqinwei. All rights reserved.
//

#import "QWCVideoPlayerViewController.h"
#import "QWCVideoPlayerPlayerView.h"
#import "QWCVideoPlayerViewControllerTool.h"

@interface QWCVideoPlayerViewController ()

// 视频播放组件
@property (nonatomic,strong) AVPlayer* player;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,strong) id playerTimeObserver;
@property (nonatomic,strong) QWCVideoPlayerPlayerView *playerView;

// 状态
@property (nonatomic,assign) BOOL isPlaying;
@property (nonatomic,assign) BOOL isControlEnabled;
@property (nonatomic,assign) BOOL isFullScreen;
@property (nonatomic,assign) BOOL isControlBarsShown; /**< 是否显示控制条 */

// 需存储的数据
@property (nonatomic,assign) CGFloat videoDuration; /**< 视频总时间长度 */
@property (nonatomic,assign) CGFloat currentTime;

// 屏幕旋转相关
@property (nonatomic,assign) UIDeviceOrientation currentOrientaion;
@property (nonatomic,assign) CGRect originalFrame;

// 控制组件 controlView
@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *fullScreenButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;

// topBarView
@property (weak, nonatomic) IBOutlet UIView *topBarView;
@property (weak, nonatomic) IBOutlet UIButton *quitButton;

// 用于动画的约束
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controlViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBarViewTopConstraint;


@end

@implementation QWCVideoPlayerViewController

#pragma mark - setter and getter

-(void) setVideoUrl:(NSString *)videoUrl{
    
    // 判断是否是重复读取url
    if(_videoUrl != videoUrl ){
        
        _videoUrl = videoUrl;
        
        if ( _videoUrl == nil ) {
            
            return;
        }
        
        NSURL *url = [NSURL URLWithString:videoUrl];
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
        NSArray *requiredKeys = @[@"playable"];
        
        [asset loadValuesAsynchronouslyForKeys:requiredKeys completionHandler:^{
           
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self prepareToPlayAsset:asset andRequiredKeys:requiredKeys];
            });
        }];
    }
}

-(void) setIsPlaying:(BOOL)isPlaying{
    
    _isPlaying = isPlaying;
    
    if (_isPlaying) {
        
        [self.playButton setImage:[UIImage imageNamed:@"QWCVideoPlayer_pause" ] forState:UIControlStateNormal];
        
        [self.player play];
    }else{
        
        [self.playButton setImage:[UIImage imageNamed:@"QWCVideoPlayer_play" ] forState:UIControlStateNormal];

        [self.player pause];
    }
}

-(void) setIsControlEnabled:(BOOL)isControlEnabled{
    
    _isControlEnabled             = isControlEnabled;
    self.playButton.enabled       = isControlEnabled;
    self.slider.enabled           = isControlEnabled;
    self.fullScreenButton.enabled = isControlEnabled;
    
}

-(void) setVideoDuration:(CGFloat)videoDuration{
    
    _videoDuration = videoDuration;
    
    // 更新与videoDuration相绑定的ui组件
    
    [self updateTimeLabel];
}

-(void) setCurrentTime:(CGFloat)currentTime{
    
    _currentTime = currentTime;
    
    // 更新与currentTime相绑定的ui组件
    
    [self updateTimeLabel];

}

-(void) setIsControlBarsShown:(BOOL)isControlBarsShown{
    
    _isControlBarsShown = isControlBarsShown;
    
    if ( _isControlBarsShown ) {
        
        [self showControlViews];
        
    }else{
        
        [self hideControlViews];
    }
}

#pragma mark - 页面启动

-(void) viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    // 退出页面之前，可能关闭过用户操作许可
    
    self.view.userInteractionEnabled = YES;
}

-(void) viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:animated];
    
    self.isPlaying = NO;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setupViews];
    
}

-(void) setupViews{
    
    
    // 侦听方向变化
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // 侦听屏幕点击
    [self.view addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapScreen:)]];
    
    [self.quitButton addTarget:self action:@selector(handleQuitButton) forControlEvents:UIControlEventTouchUpInside];
    
    [self.fullScreenButton addTarget:self action:@selector(handleFullScreenButton) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton addTarget:self action:@selector(handlePlayButton) forControlEvents:UIControlEventTouchUpInside];
    
    [self.slider addTarget:self action:@selector(handleSliding:) forControlEvents:UIControlEventValueChanged];
    [self.slider addTarget:self action:@selector(handleSlideFinished:) forControlEvents:UIControlEventTouchUpInside];
    

    // 设置初始状态
    
    [self.slider setValue:0.0f];
    self.isControlBarsShown = YES;
    
    // 视频加载成功前，禁止对视频的控制操作
    self.isControlEnabled = NO;
    
    // 设置旋转相关属性
    self.originalFrame = CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width , [UIScreen mainScreen].bounds.size.height);
    
}


-(void) prepareToPlayAsset:( AVURLAsset *)asset andRequiredKeys:(NSArray *)keys {
    
    // 判断视频是否存在异常
    
    [keys enumerateObjectsUsingBlock:^( NSString *key , NSUInteger idx, BOOL * stop) {
       
        NSError *error;
        
        AVKeyValueStatus status = [asset statusOfValueForKey:key error:&error];
        
        if ( status == AVKeyValueStatusFailed ) {
            
            // 报错
            [self showFailedAlertWithReason:@"视频加载失败"];
            return ;
        }
        
    }];
    
    
    if (!asset.playable) {
        
        [self showFailedAlertWithReason:@"该视频无法播放"];
        return;
    }
    
    // 创建 playerItem
    
    if (self.playerItem) {
        
        // 删掉之前可能存在的侦听器
        [self.playerItem removeObserver:self forKeyPath:@"status"];
    }
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    // 给AVPlayerItem 添加侦听器来查看其 status 属性，用于更新视频播放和暂停的状态
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    
    // 创建 player
    
    if (!self.player) {
        
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    }
    if (self.player.currentItem != self.playerItem) {
        
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    }
    
    // 给AVPlayer添加侦听器用于定时移动滑动条及更新播放时间数字
    
    [self removePlayerTimeObserver];
    
    __weak typeof(self) weakSelf = self;
    
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake( 1.0, 1.0) queue:nil usingBlock:^(CMTime time) {
       
        // 定时更新滑块位置
        
        __strong typeof(self) strongSelf = weakSelf;
        
        if ( strongSelf.videoDuration ) {
         
            float timeRatio = CMTimeGetSeconds(time) / strongSelf.videoDuration;
            [strongSelf.slider setValue:timeRatio animated:YES];
            
            // 更新当前时间
            
            strongSelf.currentTime = time.value / time.timescale;
        
        }
        
    }];
    
    // 创建 playerView
    
    self.playerView = [[QWCVideoPlayerPlayerView alloc] initWithFrame:self.view.frame];
    self.playerView.player = self.player;
    self.playerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.playerView.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view insertSubview:self.playerView belowSubview:self.controlView];
    
    // 给 playerView添加约束，（如果不添加约束，在旋转之后，其位置难以控制）
    NSArray* verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_playerView]|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_playerView)];
    NSArray* horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[_playerView]|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_playerView)];
    
    [self.view addConstraints:verticalConstraints];
    [self.view addConstraints:horizontalConstraints];

    [self.player play];

    
}

#pragma mark - 事件处理

-(void) handleTapScreen:(UITapGestureRecognizer *)tap{
    
    CGPoint tapPoint = [tap locationInView:self.view];
    
    if (( !CGRectContainsPoint( self.topBarView.frame, tapPoint) ) && ( !CGRectContainsPoint(self.controlView.frame, tapPoint) )) {
        
        self.isControlBarsShown = !self.isControlBarsShown;
        
    }
    
}

-(void) handleFullScreenButton{
    
    // 全屏或退出全屏
    if (self.isFullScreen) {
        
        [self rotatePortrait];
    }else{
        
        [self rotateRight];
    }
}

-(void) handlePlayButton{
    
    self.isPlaying = !self.isPlaying;
}

-(void) handleSliding:(UISlider *)slider{
    
    self.isPlaying = NO;
    
    CGFloat targetSeconds = slider.value * self.videoDuration;

    self.currentTime = targetSeconds;
    
}

-(void) handleSlideFinished:(UISlider *)slider{
    
    CGFloat targetSeconds = slider.value * self.videoDuration;
    CMTime targetCMSeconds = CMTimeMakeWithSeconds( targetSeconds, self.player.currentItem.duration.timescale );
    
    __weak typeof(self) weakSelf = self;
    
    [self.player seekToTime:targetCMSeconds completionHandler:^(BOOL finished) {
        
        __strong typeof(self) strongSelf = weakSelf;
        
        strongSelf.isPlaying = YES;
        
        strongSelf.currentTime = targetSeconds;

    }];
    
}

-(void) handleQuitButton{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 设备旋转相关

/**
 *  设置旋转过程是否自己完全控制
 *
 *  @return return value description
 */
-(BOOL)shouldAutorotate{
    
    return YES; // 让系统自动旋转屏幕上的View，只要设置好autoLayout，自动旋转的效果很平滑。且playerView也会根据横竖屏相应的屏幕大小自动调整视频显示尺寸
}

/**
 *  处理屏幕旋转，该代码注释掉，使用ViewController 的autorotate来处理即可
 *
 *  @param notification 附带旋转信息的notification
 */
//-(void) handleDeviceOrientationChanged:(NSNotification *)notification{
//    
//}

-(void) rotatePortrait{
    
    [UIView animateWithDuration:0.35f animations:^{
        
        self.view.transform = CGAffineTransformIdentity;
        
        self.view.frame = self.originalFrame;
        
    } completion:^(BOOL finished) {
        
        self.isFullScreen = NO;
        
        self.currentOrientaion = UIDeviceOrientationPortrait;
        
    }];
    
}

-(void) rotateRight{

    if (self.isFullScreen) {

        self.view.transform = CGAffineTransformIdentity;
    }

    CGRect landFrame = [self getLandscapeFrame];

    [UIView animateWithDuration:0.35f animations:^{

        self.view.frame = landFrame;

        self.view.transform = CGAffineTransformMakeRotation(-M_PI_2);

    } completion:^(BOOL finished) {

        self.isFullScreen = YES;

        self.currentOrientaion = UIDeviceOrientationLandscapeRight;


    }];

}


-(CGRect) getLandscapeFrame{
    
    CGRect frame;
    
    CGFloat originalWidth  = self.originalFrame.size.width;
    CGFloat originalHeight = self.originalFrame.size.height;
    
    frame.origin.x    = -( originalHeight - originalWidth ) / 2;
    frame.origin.y    = ( originalHeight - originalWidth ) / 2;
    frame.size.width  = originalHeight;
    frame.size.height = originalWidth;
    
    return frame;
}


#pragma mark - 业务逻辑

-(void) showControlViews{
    
    self.topBarView.hidden  = NO;
    self.controlView.hidden = NO;

    if ( self.controlViewBottomConstraint.constant < 0 ) {
        
        [UIView animateWithDuration:0.35f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.5f options:0 animations:^{
            
            self.topBarViewTopConstraint.constant     = 0.0f;
            self.controlViewBottomConstraint.constant = 0.0f;
            
            [self.view layoutIfNeeded];
            
            // 动画执行过程中禁止用户操作，因为如果这时候操作，会影响动画执行效果，以及再执行动画时出现异常
            self.view.userInteractionEnabled = NO;
            
        } completion:^(BOOL finished) {
            
            [self.view layoutIfNeeded];

            self.view.userInteractionEnabled = YES;

        }];
    }

}

-(void) hideControlViews{
    
    
    if ( self.controlViewBottomConstraint.constant >= 0) {
        
        [UIView animateWithDuration:0.35f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.5f options:0 animations:^{
            
            self.topBarViewTopConstraint.constant     = -70.0f;
            self.controlViewBottomConstraint.constant = -70.0f;
            
            [self.view layoutIfNeeded];
            
            // 动画执行过程中禁止用户操作，因为如果这时候操作，会影响动画执行效果，以及再执行动画时出现异常
            self.view.userInteractionEnabled = NO;

        } completion:^(BOOL finished) {
            
            [self.view layoutIfNeeded];
            
            self.topBarView.hidden  = YES;
            self.controlView.hidden = YES;
            
            self.view.userInteractionEnabled = YES;

        }];
    }
    
}

-(void) showFailedAlertWithReason:(NSString *) reason{

    if (NSClassFromString(@"UIAlertView")) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:reason message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        
        [alertView show];
        
    }else{
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:reason
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *buttonAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:buttonAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    
    

}


-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"status"]) {
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        
        switch (status) {
            case AVPlayerStatusReadyToPlay:
            {
                self.isPlaying = YES;
                self.isControlEnabled = YES;
                
                AVPlayerItem * playerItem = (AVPlayerItem *)object;
                
                //只有在播放状态才能获取视频时间长度
                self.videoDuration = CMTimeGetSeconds(playerItem.asset.duration);
                
            }break;
                
            case AVPlayerStatusFailed:
            {
                self.isPlaying = NO;
                [self showFailedAlertWithReason:@"播放启动失败"];
            
            }break;
                
            case AVPlayerStatusUnknown:
            {
                self.isPlaying = NO;

            }break;
            default:
                break;
        }
    }
}

-(void) updateTimeLabel{
    
    self.timeLabel.text = [NSString stringWithFormat:@"%@ / %@", [QWCVideoPlayerViewControllerTool timeStringWithTimeInterval:self.currentTime],[QWCVideoPlayerViewControllerTool timeStringWithTimeInterval:self.videoDuration] ];
}


#pragma mark - 销毁方法

-(void) removePlayerTimeObserver{
    
    if (self.playerTimeObserver) {
        
        [self.player removeTimeObserver:self.playerTimeObserver];
    }
}

-(void) dealloc{
    
    // 销毁侦听器
    
    [self removePlayerTimeObserver];
    
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 取消仍然在读取视频数据的进程
    
    [self.player cancelPendingPrerolls];
    
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    // 收到内存警告，则关闭该页面
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
