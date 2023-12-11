//
//  SNKBackTrace.h
//  Pods-SNKThreadMonitor_Example
//
//  Created by Jocer on 2023/8/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SNKBackTrace : NSObject
// 自解析
@property (nonatomic, readonly, strong) NSMutableArray <NSString *>*fnames;
@property (nonatomic, readonly, strong) NSMutableArray <NSString *>*addresses;
@property (nonatomic, readonly, strong) NSMutableArray <NSString *>*symbols;
@property (nonatomic, readonly, strong) NSMutableArray <NSNumber *>*offsets;
@property (nonatomic, readonly, copy) NSString *symbolsDescription;

// 供外部解析
@property (nonatomic, readonly, strong) NSMutableArray <NSNumber *>*machHeaders;
@property (nonatomic, readonly, strong) NSMutableArray <NSNumber *>*lrAddress;

@property (nonatomic, readonly, assign) thread_t thread;
@property (nonatomic, readonly, copy) NSString *queueName;
@property (nonatomic, readonly, copy) NSString *threadName;
+ (instancetype)backTraceWith:(thread_t)thread;
+ (instancetype)backTraceWith:(thread_t)thread deep:(NSInteger)deep;
@end

NS_ASSUME_NONNULL_END
