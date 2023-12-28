//
//  SNKAPMTracker.h
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/21.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SNKAPMTimeItem.h"
#import "SNKAPMMemoryItem.h"
#import "SNKAPMANRTracker.h"

typedef NS_ENUM(NSUInteger, SNKAPMTrackerUploadType) {
    SNKAPMTrackerUploadTypeSnake = 0,  // 贪吃蛇大作战平台
    SNKAPMTrackerUploadTypeAPM = 1,    //数数性能平台
};


@interface SNKAPMTracker : NSObject

- (instancetype)initWithUploadType:(SNKAPMTrackerUploadType)uploadType;

// 自定义事件
- (void)trackWithEvent:(NSString *)eventId dict:(NSDictionary *)dict;

#pragma mark - 时长
- (void)startTimeTrackWithEventId:(NSString *)eventId;
- (void)addTimeTrackWithEventId:(NSString *)eventId key:(NSString *)key;
- (void)endTimeTrackWithEventId:(NSString *)eventId configBlock:(NSDictionary<NSString *, id> * (^)(SNKAPMTimeItem *timeItem))configBlock;

/*
 startTime方法是开始时长统计的开始节点
 eventId:事件名称
 key:记录开始节点的耗时参数名称
 */

- (void)startTimeTrackWithEventId:(NSString *)eventId key:(NSString *)key;

/*
 addTime方法可能调用多次，记录一个eventId中多个时间节点耗时参数
 eventId:事件名称
 key:记录该事件的过程中某个节点的耗时参数名称
 toKey:用于计算上面key参数确定的节点相对于toKey节点的时间，传空默认是到endTime节点的时间
 
 */
- (void)addTimeTrackWithEventId:(NSString *)eventId key:(NSString *)key toKey:(NSString *)toKey;

/*
 finishTime方法调用表示eventId的事件已经结束，会真正打点，内部自动计算addTime添加的中间节点的时间
 eventId:事件名称
 configBlock:返回eventId这个点的一些自定义参数,curTimeDic是计算好的各节点的时间
 
 */
- (void)finishTimeTrackWithEventId:(NSString *)eventId configBlock:(NSDictionary<NSString *, id> * (^)(NSDictionary *curTimeDic))configBlock;

#pragma mark - 内存变化
- (void)startMemoryTrackWithEventId:(NSString *)eventId;
- (void)addMemoryTrackWithEventId:(NSString *)eventId key:(NSString *)key;
- (void)endMemoryTrackWithEventId:(NSString *)eventId configBlock:(NSDictionary<NSString *, id> * (^)(SNKAPMMemoryItem *memoryItem))configBlock;

#pragma mark - 内存采样
- (void)startMemoryCapture;
- (void)endMemoryCapture;

#pragma mark - 帧率



#pragma mark - 卡顿
- (void)startANRCapture;
- (void)endANRCapture;


#pragma mark - 崩溃率


#pragma mark - App 启动耗时
- (void)appLaunchTimeCaptureTime:(NSInteger)time;
@end

