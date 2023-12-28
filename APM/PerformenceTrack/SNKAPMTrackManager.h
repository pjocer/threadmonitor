//
//  SNKAPMTrackManager.h
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/25.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SNKAPMTracker.h"

/// 目前部分数据需要打点到性能平台，部分数据需要打点到业务分析上，mgr管理两个tracker
@interface SNKAPMTrackManager : NSObject

+ (instancetype)sharedManager;

- (void)tdSDKLogin;

#pragma mark - App 重点页面内存值记录
//团战模式游戏开始时内存大小，单位MB
- (void)teamGameStartTrackMem;
//语音房页面创建时内存大小，单位MB
- (void)createVoiceRoomTrackMem;
//用户主页可见时的页面的内存，单位MB
- (void)profileVCDidAppearTrackMem;
//cocos页面可见时的页面的内存，单位MB
- (void)cocosDidAppearTrackMemWithGameId:(NSNumber *)gameId;
//进入无尽模式之前的内存占用，单位MB
- (void)singleGameStartTrackMem;
#pragma mark - App 重点页面启动时长记录
// loading页可见是的耗时
- (void)firstVCDidAppearTimeCost;
// 首页可见是的耗时
- (void)homeVCTimeCostStart;
- (void)homeVCDidAppearTimeCost;
// 加载启动配置的耗时
- (void)loadConfigTimeCostStart;
- (void)loadConfigEndTimeCost;
// 加载banner配置的耗时
- (void)loadBannerDataTimeCostStart;
- (void)loadBannerDataEndTimeCost;
// 加载个人资料页的耗时
- (void)loadProfileHomeVCTimeCostStart;
- (void)loadProfileHomeVCDidAppearTimeCost;
// 加载webview的耗时,webview加载时间t1,H5加载时间t2,总时间t3
- (void)webviewLoadTimeCostStartWithVC:(UIViewController *)vc;
- (void)webviewLoadEndTimeCostWithVC:(UIViewController *)vc;
- (void)webviewH5EndLoadTimeCostWithUrl:(NSString *)url vc:(UIViewController *)vc h5loadTime:(NSInteger)time;

#pragma mark - 团战卡顿打点，一帧大于40ms算卡顿
//流程就是在渲染的每一帧都计算一下帧间隔，如果某一个帧间隔大于40ms，就开启采样，采样6帧（大约100ms），如果这6帧里面最后一帧没有超过40ms，则直接结束本次采样，并上报本次采样的最大帧间隔等数据，如果最后一帧仍然大于40ms，就认为后面可能还会发生卡顿，所以就会立刻开启下一轮6帧的采样，和前面6帧采样是一样的策略，如果连续采样时长超过1秒，就强制结束，并上报
- (void)teamGameFrameCurTime:(NSTimeInterval)time length:(NSInteger)length;
- (void)teamGameFPSCheckReset;

#pragma mark - 团战udp延迟打点
- (void)teamGameUdpDeltaTrackReset;
- (void)teamGameUdpDelta:(NSInteger)delta;
- (void)teamGameEndUploadUdpDeltas;

@property (nonatomic, strong) SNKAPMTracker *snakeTracker;
@property (nonatomic, strong) SNKAPMTracker *apmTracker;

@end
