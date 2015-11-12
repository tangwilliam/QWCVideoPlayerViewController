//
//  ViewController.m
//  QWCVideoPlayerViewControllerDemo
//
//  Created by qinwei on 15/11/10.
//  Copyright © 2015年 tangqinwei. All rights reserved.
//

#import "ViewController.h"
#import "QWCVideoPlayerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)handlePlayVideoButton:(id)sender {

    NSString *url = @"http://www.devqinwei.com/QWCVideoPlayerViewConrollerDemo.mp4";
//    @"http://v.jxvdy.com/sendfile/w5bgP3A8JgiQQo5l0hvoNGE2H16WbN09X-ONHPq3P3C1BISgf7C-qVs6_c8oaw3zKScO78I--b0BGFBRxlpw13sf2e54QA";
    //@"http://7xjkt1.com2.z0.glb.qiniucdn.com/videos/video1.3gp";
    
    QWCVideoPlayerViewController *videoPlayerViewController =  [[QWCVideoPlayerViewController alloc] initWithNibName:nil bundle:nil];
    videoPlayerViewController.videoUrl = url;
    
    if (videoPlayerViewController) {
    
        [self presentViewController:videoPlayerViewController animated:YES completion:nil];

    }else{
        
        NSLog(@"创建播放器失败");
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
