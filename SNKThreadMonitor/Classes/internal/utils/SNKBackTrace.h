//
//  SNKBackTrace.h
//  Pods-SNKThreadMonitor_Example
//
//  Created by Jocer on 2023/8/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SNKBackTrace : NSObject
@property (nonatomic, readonly, copy) NSArray <NSString *>*symbols;
@property (nonatomic, readonly, copy) NSArray <NSString *>*addresses;
@property (nonatomic, readonly, copy) NSString *symbolsDescription;
// TODO: 以NSObject对象的形式保存调用栈及地址信息
+ (instancetype)backTraceWith:(thread_t)thread;

+ (NSString *)callStackSymbolsDescription:(thread_t)thread;
@end

NS_ASSUME_NONNULL_END
