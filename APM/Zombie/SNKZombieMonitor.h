//
//  SNKZombieMonitor.h
//  SnakeGameSingle
//
//  Created by karos li on 2023/5/15.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SNKAPMConfig;

/// 僵尸对象监听器
@interface SNKZombieMonitor : NSObject
+ (void)startWithConfig:(SNKAPMConfig *)config;
+ (void)stopByConfig;
+ (void)stop;
@end
