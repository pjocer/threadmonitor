//
//  SNKAPMTrackManager.m
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/21.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "SNKAPMTracker.h"
#import "SNKTimer.h"
#import "UIDevice+Hardware.h"
#import "UIViewController+Utils.h"
#import "SNKTDTracker.h"

#define kSNKAPMTrackDefaultTimeUpdate @"SNKAPM_TIME_UPDATE"
#define kSNKAPMTrackDefaultMemoryUpdate @"SNKAPM_MEMORY_UPDATE"


@interface SNKAPMTracker()

@property(nonatomic, assign) SNKAPMTrackerUploadType uploadType;

@property(nonatomic, strong) NSMutableDictionary *trackEventDict;
@property(nonatomic, strong) NSOperationQueue *trackQueue;
@property(nonatomic, strong) SNKTimer *timer;

@property(nonatomic, strong) SNKAPMANRTracker *anrTracker;
@property(nonatomic, assign) BOOL hasTrackMemoryLimit;

@end

@implementation SNKAPMTracker

- (instancetype)initWithUploadType:(SNKAPMTrackerUploadType)uploadType {
    if (self = [super init]) {
        self.trackEventDict = [NSMutableDictionary dictionary];
        self.trackQueue = [[NSOperationQueue alloc] init];
        self.trackQueue.maxConcurrentOperationCount = 1;
        self.uploadType = uploadType;
    }
    return self;
}

#pragma mark - Time
- (void)startTimeTrackWithEventId:(NSString *)eventId {
    
    [self.trackQueue addOperationWithBlock:^{
        NSString *timeKey = [self timeKeyWithEventId:eventId];
        if (!timeKey) return;
        SNKAPMTimeItem *timeItem = [SNKAPMTimeItem new];
        self.trackEventDict[timeKey] = timeItem;
        [timeItem setTimeWithKey:SNKAPMTimeItemStartKey];
    }];

}

- (void)addTimeTrackWithEventId:(NSString *)eventId key:(NSString *)key {
    
    [self.trackQueue addOperationWithBlock:^{
        NSString *timeKey = [self timeKeyWithEventId:eventId];
        if (!timeKey || SNKStringIsEmpty(key)) return;
        SNKAPMTimeItem *timeItem = self.trackEventDict[timeKey];
        if (!timeItem) return;
        [timeItem setTimeWithKey:key];
    }];
}

- (void)endTimeTrackWithEventId:(NSString *)eventId configBlock:(NSDictionary<NSString *, id> * (^)(SNKAPMTimeItem *timeItem))configBlock {
    [self.trackQueue addOperationWithBlock:^{
        NSString *timeKey = [self timeKeyWithEventId:eventId];
        if (!timeKey) return;
        SNKAPMTimeItem *timeItem = self.trackEventDict[timeKey];
        if (!timeItem) return;
        [timeItem setTimeWithKey:SNKAPMTimeItemEndKey];
        NSDictionary *dict = nil;
        if (configBlock) {
            dict = configBlock(timeItem);
        }
        
        if (SNKDictIsEmpty(dict)) {
            dict = @{kSNKAPMTrackDefaultTimeUpdate : @(timeItem.endTime - timeItem.startTime)};
        }
        
        [self trackWithEvent:eventId dict:dict];
        [self.trackEventDict removeObjectForKey:timeKey];
    }];
}

- (NSString *)timeKeyWithEventId:(NSString *)eventId {
    if (SNKStringIsEmpty(eventId)) return nil;
    return [NSString stringWithFormat:@"apm_time_%@",eventId];
}

- (void)startTimeTrackWithEventId:(NSString *)eventId key:(NSString *)key {
    [self addTimeTrackWithEventId:eventId key:key toKey:nil];
}

- (void)addTimeTrackWithEventId:(NSString *)eventId key:(NSString *)key toKey:(NSString *)toKey {
    if (SNKStringIsEmpty(eventId)) {
        return;
    }
    SNKAPMTimeItem *item = self.trackEventDict[eventId];
    if (!item) {
        item = [SNKAPMTimeItem new];
    }
    [item addkey:key toKey:toKey];
    self.trackEventDict[eventId] = item;
}

- (void)finishTimeTrackWithEventId:(NSString *)eventId configBlock:(NSDictionary<NSString *, id> * (^)(NSDictionary *curTimeDic))configBlock {
    
    [self.trackQueue addOperationWithBlock:^{
        if (SNKStringIsEmpty(eventId)) {
            return;
        }
        SNKAPMTimeItem *item = self.trackEventDict[eventId];
        if (item == nil) {
            return;
        }
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        
        NSDictionary *timeDic = [item genTimeDic];
        [param addEntriesFromDictionary:timeDic];
        NSDictionary *dict = nil;
        if (configBlock) {
            dict = configBlock(param);
            [param addEntriesFromDictionary:dict];
            SNKLogInfo(@"time param is %@",param);
        }
        
        [self trackWithEvent:eventId dict:param];
        [self.trackEventDict removeObjectForKey:eventId];
    }];
}

#pragma mark - Memory
- (void)startMemoryTrackWithEventId:(NSString *)eventId {
   
    [self.trackQueue addOperationWithBlock:^{
        NSString *memoryKey = [self memoryKeyWithEventId:eventId];
        if (!memoryKey) return;
        SNKAPMMemoryItem *memoryItem = [SNKAPMMemoryItem new];
        self.trackEventDict[memoryKey] = memoryItem;
        [memoryItem setMemoryWithKey:SNKAPMMemoryItemStartKey];
    }];
    
}

- (void)addMemoryTrackWithEventId:(NSString *)eventId key:(NSString *)key {
    
    [self.trackQueue addOperationWithBlock:^{
        NSString *memoryKey = [self memoryKeyWithEventId:eventId];
        if (!memoryKey|| SNKStringIsEmpty(key)) return;
        SNKAPMMemoryItem *memoryItem = self.trackEventDict[memoryKey];
        if (!memoryItem) return;
        [memoryItem setMemoryWithKey:key];
    }];
    
}

- (void)endMemoryTrackWithEventId:(NSString *)eventId configBlock:(NSDictionary<NSString *, id> * (^)(SNKAPMMemoryItem *memoryItem))configBlock {
    [self.trackQueue addOperationWithBlock:^{
        NSString *memoryKey = [self memoryKeyWithEventId:eventId];
        if (!memoryKey) return;
        SNKAPMMemoryItem *memoryItem = self.trackEventDict[memoryKey];
        if (!memoryItem) return;
        [memoryItem setMemoryWithKey:SNKAPMMemoryItemEndKey];
        NSDictionary *dict = nil;
        if (configBlock) {
            dict = configBlock(memoryItem);
        }
        
        if (SNKDictIsEmpty(dict)) {
            dict = @{kSNKAPMTrackDefaultMemoryUpdate : @(memoryItem.endMemory - memoryItem.startMemory)};
        }
        
        [self trackWithEvent:eventId dict:dict];
        [self.trackEventDict removeObjectForKey:memoryKey];
    }];
}

- (NSString *)memoryKeyWithEventId:(NSString *)eventId {
    if (SNKStringIsEmpty(eventId)) return nil;
    return [NSString stringWithFormat:@"apm_memory_%@",eventId];
}

#pragma mark - 内存采样

- (void)startMemoryCapture {
    [self.timer cancelTimer];
    self.timer = [SNKTimer new];
    WEAKSELF;
    [self.timer snk_scheduledTimerWithTimeInterval:10 repeats:YES callback:^(NSTimer * _Nonnull timer) {
        [weakSelf.trackQueue addOperationWithBlock:^{ // 执行内存采样
            NSUInteger currentMemroy = [SNKAPMMemoryItem currentMemory];
            // 判断阈值
            if (currentMemroy >= [weakSelf deviceLimitMemory]) {
                if (weakSelf.hasTrackMemoryLimit) return;
                float memory = currentMemroy / 1024.0 / 1024.0;
                NSString *device = [UIDevice deviceModelName];
                [weakSelf trackWithEvent:@"Mem_Event" dict:@{
                    @"curMem" : @(memory),
                    @"device" : device,
                    @"viewHierarchy" : [UIViewController presentedVCDescription],
                }];
                weakSelf.hasTrackMemoryLimit = YES;
            } else {
                weakSelf.hasTrackMemoryLimit = NO;
            }
        }];
    }];
}

- (void)endMemoryCapture {
    [self.timer cancelTimer];
}


#pragma mark - 卡顿
- (void)startANRCapture {
    [self.anrTracker startANRCapture];
}
- (void)endANRCapture {
    [self.anrTracker endANRCapture];
}

// https://juejin.cn/post/6911177006394638343#heading-2, 目前简单的统计为50%
- (NSUInteger)deviceLimitMemory {
    NSUInteger physicalMemory = [UIDevice physicalMemory];
    if ([UIDevice lessThanOrEqual1GMemoryDevice]) {
        return physicalMemory * 0.45;
    }
    return physicalMemory * 0.5;
}

- (void)appLaunchTimeCaptureTime:(NSInteger)time {
    if (time > 200000 || time <= 0) {
        return;
    }
    [self trackWithEvent:@"AppStart_Event" dict:@{
        @"appstart" : @(time)
    }];
}


- (void)trackWithEvent:(NSString *)eventId dict:(NSDictionary *)dict {
    if (self.uploadType == SNKAPMTrackerUploadTypeSnake) {
        SNKTrack(eventId, dict);
    } else {
        SNKTDTrack(eventId, dict);
    }
}

#pragma mark - property
- (SNKAPMANRTracker *)anrTracker {
    if (!_anrTracker) {
        _anrTracker = [[SNKAPMANRTracker alloc] init];
        WEAKSELF
        _anrTracker.anrDetectedBlock = ^{
            [weakSelf.trackQueue addOperationWithBlock:^{
                NSString *device = [UIDevice deviceModelName];
                [weakSelf trackWithEvent:@"ANR_Event" dict:@{
                    @"device" : device,
                    @"viewHierarchy" : [UIViewController presentedVCDescription],
                }];
            }];
        };
    }
    return _anrTracker;
}

@end
