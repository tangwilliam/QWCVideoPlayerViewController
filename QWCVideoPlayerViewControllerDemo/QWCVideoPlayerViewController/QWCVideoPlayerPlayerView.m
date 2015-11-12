//
//  QWCVideoPlayerPlayerView.m
//  QWCVideoPlayerViewControllerDemo
//
//  Created by qinwei on 15/11/10.
//  Copyright © 2015年 tangqinwei. All rights reserved.
//

#import "QWCVideoPlayerPlayerView.h"

@implementation QWCVideoPlayerPlayerView

+(Class) layerClass{
    
    return [AVPlayerLayer class];
}

-(AVPlayer *)player{
    
    return [( AVPlayerLayer *)self.layer player];
}

-(void) setPlayer:(AVPlayer *)player{
    
    [(AVPlayerLayer *)self.layer setPlayer:player];
}

-(void) setVideoGravity:(NSString *)videoGravity{
    
    [(AVPlayerLayer *)self.layer setVideoGravity:videoGravity];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
