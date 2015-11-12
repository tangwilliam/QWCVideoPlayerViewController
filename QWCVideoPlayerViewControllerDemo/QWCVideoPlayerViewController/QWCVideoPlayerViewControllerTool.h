//
//  QWCVideoPlayerViewControllerTool.h
//  QWCVideoPlayerViewControllerDemo
//
//  Created by qinwei on 15/11/11.
//  Copyright © 2015年 tangqinwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QWCVideoPlayerViewControllerTool : NSObject

/**
 *  根据时间(秒数)，来生成 00:00:00格式的字符串
 *
 *  @param timeInterval 时间/秒
 *
 *  @return 00:00:00格式的字符串
 */
+(NSString *) timeStringWithTimeInterval:(CGFloat)timeInterval;

@end
