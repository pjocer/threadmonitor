//
//  SNKThreadMonitorSentryReporter.m
//  SnakeGameSingle
//
//  Created by Jocer on 2023/10/23.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "SNKThreadMonitorSentryReporter.h"
#import <Sentry/Sentry.h>
#import <SNKThreadMonitor/SNKBackTrace.h>
#import "WPZombieMonitor.h"

@implementation SNKThreadMonitorSentryReporter
/**
 {
    hold_lock_thread_id1 : [
        wait_lock_thread_id1
        wait_lock_thread_id2
    ],
    hold_lock_thread_id2 : [
        wait_lock_thread_id
    ]
 }
 */
+ (void)reportDeadLockToSentry:(NSString *)name title:(NSString *)title desc:(NSString *)desc extra:(NSDictionary *)extra callStacks:(NSArray <SNKBackTrace *>*)callStacks {
    NSMutableArray *threads = [NSMutableArray arrayWithCapacity:callStacks.count];
    [callStacks enumerateObjectsUsingBlock:^(SNKBackTrace * _Nonnull backTrace, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray *frames = [NSMutableArray arrayWithCapacity:backTrace.fnames.count];
        [backTrace.fnames enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SentryFrame *frame = [[SentryFrame alloc] init];
            frame.function = backTrace.symbols[idx];
            frame.package = obj;
            frame.instructionAddress = wpzombie_formatHexAddress(backTrace.lrAddress[idx]);
            frame.instruction = backTrace.lrAddress[idx].unsignedLongLongValue;
            frame.imageAddress = wpzombie_formatHexAddress(backTrace.machHeaders[idx]);
            [frames addObject:frame];
        }];
        SentryStacktrace *stackTrace = [[SentryStacktrace alloc] initWithFrames:frames registers:@{}];
        SentryThread *thread = [[SentryThread alloc] initWithThreadId:@(backTrace.thread)];
        thread.current = @(NO);
        thread.crashed = @(NO);
        thread.stacktrace = stackTrace;
        thread.name = backTrace.threadName;
        [threads addObject:thread];
    }];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentryLevelWarning];
    event.transaction = name;
    event.message = [[SentryMessage alloc] initWithFormatted:[NSString stringWithFormat:@"%@:%@\n%@", name, title, desc]];
    event.threads = threads;
    event.extra = extra;
    [SentrySDK captureEvent:event];
}
@end
