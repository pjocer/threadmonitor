//
//  WPZombieMonitor.h
//  ZombieSniffer
//
//  Created by karos li on 2023/5/15.
//

#import <Foundation/Foundation.h>

#define WPZombieMonitorM ([WPZombieMonitor sharedInstance])

static inline NSString *
wpzombie_formatHexAddress(NSNumber *value)
{
    return [NSString stringWithFormat:@"0x%016llx", [value unsignedLongLongValue]];
}

/// 监控策略
typedef NS_ENUM(NSInteger, WPZombieDetectStrategy) {
    WPZombieDetectStrategyCustomObjectOnly = 0, //只监控自定义对象, 默认使用该策略
    WPZombieDetectStrategyWhitelist = 1, //使用白名单
    WPZombieDetectStrategyAll = 2, //监控所有对象，强制过滤类除外
};

/**
 Zombie 对象监控（监控 double free 和 use after free）
 监控原理：swizzling [NSObject dealloc]方法，dealloc时只调用析构，不调用free，同时把isa指针指向WPZombie，通过消息转发机制捕捉zombie对象
 
 内存占用：还没有free的对象和调用栈占用内存比较大，可以通过maxOccupyMemorySize设置最大内存，当收到memoryWarning或超出maxOccupyMemorySize后，通过FIFO机制释放对象
 */
@interface WPZombieMonitor : NSObject

/// 监控策略，默认 WPZombieDetectStrategyCustomObjectOnly
@property (nonatomic, assign) WPZombieDetectStrategy strategy;
/// 白名单，WPZombieDetectStrategyWhitelist 时生效
@property (nonatomic, copy) NSArray<NSString*> *whiteList;
/// 强制过滤类，不受监控策略影响，主要用于过滤频繁创建的对象，比如log
@property (nonatomic, copy) NSArray<NSString*> *forceFilterList;

/// 最大占用内存大小，包括zombie对象大小和堆栈内存大小，默认1M
@property (nonatomic, assign) NSInteger maxOccupyMemorySize;
/// 是否记录dealloc栈，默认YES
@property (nonatomic, assign) BOOL traceDeallocStack;

/**
 * handle，监测到zombie时调用
 * @param className zombie对象名
 * @param obj zombie对象地址
 * @param selectorName selector
 * @param deallocStack 对象释放栈
 * @param zombieStack  zombie对象调用栈
 */
@property (nonatomic, strong) void (^handle)(NSString *className, void* obj, NSString *selectorName, NSArray<NSNumber *> *deallocStack, NSArray<NSNumber *> *zombieStack);

+ (instancetype)sharedInstance;
- (void)startMonitor;
- (void)stopMonitor;

@end
