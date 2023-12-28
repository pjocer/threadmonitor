//
//  SNKAPMTrackManager.m
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/25.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "SNKAPMTrackManager.h"
#import "SNKTDTracker.h"
#import <sys/sysctl.h>
#import "ConfigHelper.h"

@interface SNKAPMTrackManager()

@property(nonatomic, strong) NSMapTable *webVCInstances;

@property(nonatomic, strong) NSMutableArray *teamGameTimeArr;

@property(nonatomic, assign) BOOL isTeamGameFirstCheckTimeArr; //是否游戏开始的前几帧

@property(nonatomic, assign) NSInteger teamGameUploadArrFirstTimestamp; // 记录是否已开启记录帧数据上报，记录区间开启的时间戳

@property(nonatomic, assign) NSInteger curTotalFrameCount; // 当前检测周期内的帧总数

@property(nonatomic, assign) NSInteger curMaxDeltaTime; // 记录一个检测周期内一帧最大的耗时


@property(nonatomic, assign) BOOL launchTrackUploaded;

@property(nonatomic, strong) NSMutableArray *teamGameUdpDeltaArr;

@end


@implementation SNKAPMTrackManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static SNKAPMTrackManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[SNKAPMTrackManager alloc] init];
    });
    return instance;
}

- (void)tdSDKLogin {
    [SNKTDTracker login];
}



- (instancetype)init {
    if (self = [super init])  {
        self.snakeTracker = [[SNKAPMTracker alloc] initWithUploadType:SNKAPMTrackerUploadTypeSnake];
        self.apmTracker = [[SNKAPMTracker alloc] initWithUploadType:SNKAPMTrackerUploadTypeAPM];
        self.webVCInstances = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    }
    return self;
}

#pragma mark - App 重点页面内存值记录

//团战模式游戏开始时内存大小，单位MB
- (void)teamGameStartTrackMem {
    NSDictionary *params = [self p_trackMemParams];
    [self.apmTracker trackWithEvent:@"SnakeTM_heap_used_MB_Event" dict:params];
}
//语音房页面创建时内存大小，单位MB
- (void)createVoiceRoomTrackMem {
    NSDictionary *params = [self p_trackMemParams];
    [self.apmTracker trackWithEvent:@"VoiceRoom_heap_used_MB_Event" dict:params];
}
//用户主页可见时的页面的内存，单位MB
- (void)profileVCDidAppearTrackMem {
    
    NSDictionary *params = [self p_trackMemParams];
    [self.apmTracker trackWithEvent:@"User_Center_Heap_Memory_Event" dict:params];
}
//cocos页面可见时的页面的内存，单位MB
- (void)cocosDidAppearTrackMemWithGameId:(NSNumber *)gameId {
    NSMutableDictionary *params = [self p_trackMemParams];
    params[@"cocos_game_id"] = gameId;
    [self.apmTracker trackWithEvent:@"CocosRuntime_heap_used_MB_Event" dict:params];
}

- (NSMutableDictionary *)p_trackMemParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSUInteger currentMemroy = [SNKAPMMemoryItem currentMemory];
    float memory = currentMemroy / 1024.0 / 1024.0;
    params[@"curmem"] = @(memory);
    return params;
}

- (void)singleGameStartTrackMem {
    NSDictionary *params = [self p_trackMemParams];
    [self.apmTracker trackWithEvent:@"SingleGame_heap_used_MB_Event" dict:params];
}

#pragma mark - App 重点页面启动时长记录
// loading页可见是的耗时
- (void)firstVCDidAppearTimeCost {
    if (self.launchTrackUploaded) {
        return;
    }
    self.launchTrackUploaded = YES;
    NSTimeInterval t = [SNKAPMTrackManager processStartTime];
    NSTimeInterval curDate = [[NSDate date] timeIntervalSince1970] * 1000;
    if (t > 0) {
        NSInteger time = (curDate - t);
        [self.apmTracker appLaunchTimeCaptureTime:time];
    }
    
}
// 首页可见是的耗时
- (void)homeVCTimeCostStart {
    [self.apmTracker startTimeTrackWithEventId:@"HomeVC_create_Event" key:@"homevc_create"];
}
- (void)homeVCDidAppearTimeCost {
    [self.apmTracker finishTimeTrackWithEventId:@"HomeVC_create_Event" configBlock:nil];
}
// 加载启动配置的耗时
- (void)loadConfigTimeCostStart {
    [self.apmTracker startTimeTrackWithEventId:@"LoadConfig_from_start_Event" key:@"loadconfig_from_start"];
}
- (void)loadConfigEndTimeCost {
    [self.apmTracker finishTimeTrackWithEventId:@"LoadConfig_from_start_Event" configBlock:nil];
    
}
// 加载banner配置的耗时
- (void)loadBannerDataTimeCostStart {
    
    [self.apmTracker startTimeTrackWithEventId:@"Banner_Data_Load_Event" key:@"banner_data_load"];
}
- (void)loadBannerDataEndTimeCost {
    [self.apmTracker finishTimeTrackWithEventId:@"Banner_Data_Load_Event" configBlock:nil];
    
}
// 加载个人资料页的耗时
- (void)loadProfileHomeVCTimeCostStart {
    
    [self.apmTracker startTimeTrackWithEventId:@"User_Center_Load_Event" key:@"user_center_load"];
    
}
- (void)loadProfileHomeVCDidAppearTimeCost {
    [self.apmTracker finishTimeTrackWithEventId:@"User_Center_Load_Event" configBlock:nil];
    
}

// 加载webview的耗时
- (void)webviewLoadTimeCostStartWithVC:(UIViewController *)vc {
    // cocos小游戏等不做处理
    if ([NSStringFromClass(vc.class).lowercaseString containsString:@"cocos"]) {
        return;
    }
    SNKAPMTracker *track = [self.webVCInstances objectForKey:vc];
    if (!track) {
        track = [[SNKAPMTracker alloc] initWithUploadType:SNKAPMTrackerUploadTypeAPM];
    }
    [track startTimeTrackWithEventId:@"WebView_Load_DU_Event" key:@"total_du"];
    [self.webVCInstances setObject:track forKey:vc];
}

- (void)webviewLoadEndTimeCostWithVC:(UIViewController *)vc {
    SNKAPMTracker *track = [self.webVCInstances objectForKey:vc];
    if (!track) {
        return;
    }
    [track addTimeTrackWithEventId:@"WebView_Load_DU_Event" key:@"init_du" toKey:@"total_du"];
}

- (void)webviewH5EndLoadTimeCostWithUrl:(NSString *)url vc:(UIViewController *)vc h5loadTime:(NSInteger)time{
    SNKAPMTracker *track = [self.webVCInstances objectForKey:vc];
    if (!track) {
        return;
    }
    
    [track finishTimeTrackWithEventId:@"WebView_Load_DU_Event" configBlock:^NSDictionary<NSString *,id> *(NSDictionary *curTimeDic){
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        param[@"url"] = url;
        param[@"page"] = NSStringFromClass(vc.class);
        if ([[NSURL URLWithString:url].scheme isEqualToString:@"file"]) {
            param[@"is_local_file"] = @(YES);
        }else{
            param[@"is_local_file"] = @(NO);
        }
        param[@"h5_render_du"] = @(time);
        param[@"total_du"] = @([curTimeDic[@"init_du"] integerValue] + time);
        return param;
    }];
    [self.webVCInstances removeObjectForKey:vc];
}

+ (NSTimeInterval)processStartTime
{   // 单位是毫秒
    struct kinfo_proc kProcInfo;
    if ([self processInfoForPID:[[NSProcessInfo processInfo] processIdentifier] procInfo:&kProcInfo]) {
        return kProcInfo.kp_proc.p_un.__p_starttime.tv_sec * 1000.0 + kProcInfo.kp_proc.p_un.__p_starttime.tv_usec / 1000.0;
        
    } else {
        return 0;
    }
}

+ (BOOL)processInfoForPID:(int)pid procInfo:(struct kinfo_proc*)procInfo
{
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*procInfo);
    return sysctl(cmd, sizeof(cmd)/sizeof(*cmd), procInfo, &size, NULL, 0) == 0;
}

#pragma - mark 团战耗时监控   记录6帧的时间戳，计算是否有超过40ms的帧，有就上报打点
- (void)teamGameFrameCurTime:(NSTimeInterval)time length:(NSInteger)length{
    if ([ConfigHelper config].disableTeamGameFPSCapture) return;
    NSInteger timeThreshold = 40;
    if (self.teamGameUploadArrFirstTimestamp == 0 && self.teamGameTimeArr.count > 1) {
        NSInteger deltaTime = [self.teamGameTimeArr[1] integerValue] - [self.teamGameTimeArr[0] integerValue];
        // 判断是否有超过40ms，超过了，就会记录接下来的6帧的耗时，上报打点
        if (deltaTime > timeThreshold) {
            self.teamGameUploadArrFirstTimestamp = [self.teamGameTimeArr[0] integerValue];
        }else{
            [self.teamGameTimeArr removeObjectAtIndex:0];
            self.isTeamGameFirstCheckTimeArr = NO;
        }
    }
    
    // 满6帧后，计算耗时，计算最大的耗时
    if (self.teamGameTimeArr.count % 7 == 0) {
        self.curTotalFrameCount += 6;
        NSInteger maxDeltaTime = 0; // 记录最大的帧的耗时
        BOOL shouldDot = NO;
        
        for (int i = 1; i < self.teamGameTimeArr.count; ++ i) {
            NSInteger deltaTime = [self.teamGameTimeArr[i] integerValue] - [self.teamGameTimeArr[i-1] integerValue];
            if (deltaTime > timeThreshold && deltaTime > maxDeltaTime) {
                maxDeltaTime = deltaTime;
            }
            
            // 判断最后一帧耗时，如果也
            if (i == self.teamGameTimeArr.count - 1) {
                if (deltaTime > timeThreshold) {
                    NSInteger curEndToStartTime = [self.teamGameTimeArr.lastObject integerValue] - self.teamGameUploadArrFirstTimestamp;
                    if (curEndToStartTime >= 1000) {
                        shouldDot = YES;
//                        SNKLogInfo(@"LHDEBUG---time long is %ld",curEndToStartTime);
                    }
                }else{
                    shouldDot = YES;
                }
            }
        }
//        SNKLogInfo(@"LHDEBUG---delta11 time is %ld",maxDeltaTime);
//        SNKLogInfo(@"LHDEBUG---arr count is %ld",self.teamGameTimeArr.count);
        if (shouldDot) {
            maxDeltaTime = maxDeltaTime > self.curMaxDeltaTime ? maxDeltaTime : self.curMaxDeltaTime;
            NSMutableDictionary *param = [NSMutableDictionary dictionaryWithDictionary:[self p_trackMemParams]];
            NSInteger curEndToStartTime = [self.teamGameTimeArr.lastObject integerValue] - self.teamGameUploadArrFirstTimestamp;
            NSInteger fpsAvg = 0;
            if (curEndToStartTime > 0) {
                fpsAvg = 1000 * self.curTotalFrameCount / curEndToStartTime;
                if (fpsAvg > 60) {
                    fpsAvg = 60;
                }
            }
            
            param[@"is_game_start"] = @(self.isTeamGameFirstCheckTimeArr);
            param[@"mine_snake_length"] = @(length);
            param[@"max_frame_time"] = @(maxDeltaTime);
            param[@"snake_team_fps"] = @(fpsAvg);
//            SNKLogInfo(@"LHDEBUG---fps param is %@",param);
            [self.apmTracker trackWithEvent:@"Snake_Team_FPS_Event" dict:param];
            self.isTeamGameFirstCheckTimeArr = NO;
            self.curTotalFrameCount = 0;
            self.teamGameUploadArrFirstTimestamp = 0;
            self.curMaxDeltaTime = 0;
        }else{
            self.curMaxDeltaTime = maxDeltaTime;
        }
        [self.teamGameTimeArr removeAllObjects];
    }
    [self.teamGameTimeArr addObject:@(time)];
}

- (void)teamGameFPSCheckReset {
    self.curTotalFrameCount = 0;
    self.isTeamGameFirstCheckTimeArr = YES;
    self.teamGameUploadArrFirstTimestamp = 0;
    self.curMaxDeltaTime = 0;
    [self.teamGameTimeArr removeAllObjects];
}

- (void)teamGameUdpDeltaTrackReset {
    if (ConfigHelperM.closeTeamGameNoDataUpload) {
        return;
    }
    [self.teamGameUdpDeltaArr removeAllObjects];
}

- (void)teamGameUdpDelta:(NSInteger)delta {
    if (ConfigHelperM.closeTeamGameNoDataUpload) {
        return;
    }
    [self.teamGameUdpDeltaArr addObject:@(delta)];
}

- (void)teamGameEndUploadUdpDeltas {
    if (ConfigHelperM.closeTeamGameNoDataUpload) {
        return;
    }
    if (self.teamGameUdpDeltaArr.count == 0) {
        return;
    }
    NSArray *sortedArray = [self.teamGameUdpDeltaArr sortedArrayUsingSelector:@selector(compare:)];
    NSInteger count = sortedArray.count;
    NSNumber *maxValue = sortedArray.lastObject;
    NSNumber *minValue = sortedArray.firstObject;
    NSNumber *sum = [sortedArray valueForKeyPath:@"@sum.self"];
    NSInteger average = [sum floatValue] / count;
    NSNumber *median;
    if (count % 2 == 0) {
        NSNumber *middle1 = sortedArray[count/2 - 1];
        NSNumber *middle2 = sortedArray[count/2];
        median = @(([middle1 floatValue] + [middle2 floatValue]) / 2);
    } else {
        median = sortedArray[count/2];
    }
    NSDictionary *params = @{
        @"min_td" : minValue,
        @"max_td" : maxValue,
        @"avg_td" : @(average),
        @"median_td" : median,
    };
    [self.apmTracker trackWithEvent:@"Snake_Team_NoData_Event" dict:params];
    [self.teamGameUdpDeltaArr removeAllObjects];
}

- (NSMutableArray *)teamGameTimeArr {
    if (!_teamGameTimeArr) {
        _teamGameTimeArr = [NSMutableArray array];
        _isTeamGameFirstCheckTimeArr = YES;
    }
    return _teamGameTimeArr;
}

- (NSMutableArray *)teamGameUdpDeltaArr {
    if (!_teamGameUdpDeltaArr) {
        _teamGameUdpDeltaArr = [NSMutableArray array];
    }
    return _teamGameUdpDeltaArr;
}

@end
