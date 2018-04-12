//
//  SemaphoreDetection.h
//  RunloopDetection
//
//  Created by 超级腕电商 on 2018/4/11.
//  Copyright © 2018年 超级腕电商. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SemaphoreDetection : NSObject
/*单例获取*/
+ (instancetype) sharedInstance;
/*开始检测*/
- (void) startDetection;
/*停止检测*/
- (void) endDetection;

@end
