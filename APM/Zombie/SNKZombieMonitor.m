//
//  SNKZombieMonitor.m
//  SnakeGameSingle
//
//  Created by karos li on 2023/5/15.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "SNKZombieMonitor.h"
#import "WPZombieMonitor.h"
#import "SNKAPMConfig.h"
#import "ConfigHelper.h"

@implementation SNKZombieMonitor

/// 5.6.1 首页显示后延迟多少秒后关闭 zombie 检测
static NSInteger homeShowDelayDurationStop = 0;

+ (void)startWithConfig:(SNKAPMConfig *)config {
    if (!config.zombieEnable || !config.zombie) {
        return;
    }
    
    /// 还可以优化的点：只拦截用到过的类
    /**
     https://nc6byfqd9e.feishu.cn/wiki/ZWv5wRa6bir2xBkOcjicjQPInUd
     可以配置的参数：
     采样率：僵尸对象监控本身会消耗内存和CPU，所以可以控制监控的范围，这个可以在后台配置。服务根据采用率来对 enable 做 AB
     采样策略：自定义对象；白名单（白名单列表）；全部对象
     强制过滤列表：不管什么策略，都必须经过强制过滤列表
     是否采样 dealloc 堆栈：可以获取对象 dealloc 时的堆栈
     */
    void (^WPZombieHandle)(NSString *className, void *obj, NSString *selectorName, NSArray<NSNumber *> *deallocStack, NSArray<NSNumber *> *zombieStack) = ^(NSString *className, void *obj, NSString *selectorName, NSArray<NSNumber *> *deallocStack, NSArray<NSNumber *> *zombieStack) {
        
    };
    WPZombieMonitorM.handle = WPZombieHandle;
    WPZombieMonitorM.strategy = (WPZombieDetectStrategy)config.zombie.strategy;
    WPZombieMonitorM.traceDeallocStack = WPZombieMonitorM.strategy == WPZombieDetectStrategyWhitelist;// 白名单才启用堆栈采集，因为堆栈采集消耗性能和占用内存
    WPZombieMonitorM.whiteList = config.zombie.whiteList;
    WPZombieMonitorM.forceFilterList = config.zombie.forceFilterList;
    [WPZombieMonitorM startMonitor];
    
    homeShowDelayDurationStop = config.zombie.delayDurationStop;
}

+ (void)stopByConfig {
    if (homeShowDelayDurationStop > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(homeShowDelayDurationStop * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SNKZombieMonitor stop];
        });
    }
}

+ (void)stop {
    [WPZombieMonitorM stopMonitor];
}

@end
