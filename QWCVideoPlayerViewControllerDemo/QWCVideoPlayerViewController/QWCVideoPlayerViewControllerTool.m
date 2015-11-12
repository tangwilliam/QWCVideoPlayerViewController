//
//  QWCVideoPlayerViewControllerTool.m
//  QWCVideoPlayerViewControllerDemo
//
//  Created by qinwei on 15/11/11.
//  Copyright © 2015年 tangqinwei. All rights reserved.
//

#import "QWCVideoPlayerViewControllerTool.h"

@implementation QWCVideoPlayerViewControllerTool


/**
 *  根据时间(秒数)，来生成 00:00:00格式的字符串
 *
 *  @param timeInterval 时间/秒
 *
 *  @return 00:00:00格式的字符串
 */
+(NSString *) timeStringWithTimeInterval:(CGFloat)timeInterval{
    
    NSString *string = @"00:00:00";
    
    if (timeInterval) {
        
        NSInteger hours = timeInterval / 3600;
        NSInteger minutes = ( timeInterval - hours * 3600 ) / 60;
        NSInteger seconds = (int)timeInterval % 60;
        
        if( hours ){
            
            string = [NSString stringWithFormat:@"%2ld:%02ld:%02ld", hours,minutes,seconds ];
        }else{
            
            string = [NSString stringWithFormat:@"%02ld:%02ld", minutes,seconds ];
        }

        
    }
    
    return string;
}

@end
