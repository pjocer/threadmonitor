//
//  SNKThreadMonitorSentryReporter.h
//  SnakeGameSingle
//
//  Created by Jocer on 2023/10/23.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SNKBackTrace;
@interface SNKThreadMonitorSentryReporter : NSObject
+ (void)reportDeadLockToSentry:(NSString *)name title:(NSString *)title desc:(NSString *)desc extra:(NSDictionary *)extra callStacks:(NSArray <SNKBackTrace *>*)callStacks;
@end

NS_ASSUME_NONNULL_END
