//
//  SNKTDTracker.m
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/25.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "SNKTDTracker.h"
#import "SNKAccountManager.h"
#import <ThinkingSDK/ThinkingAnalyticsSDK.h>
#import "WPAccountCache.h"


@interface SNKTDTracker()

@property(nonatomic, strong) ThinkingAnalyticsSDK *tdSDK;

@end

@implementation SNKTDTracker

+ (instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    static SNKTDTracker *instance;
    dispatch_once(&onceToken, ^{
        instance = [SNKTDTracker new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        TDConfig *config = [TDConfig defaultTDConfig];
        config.autoTrackEventType = ThinkingAnalyticsEventTypeAppViewCrash | ThinkingAnalyticsEventTypeAppStart;
#ifdef DEBUG
        config.debugMode = ThinkingAnalyticsDebug;
#endif
        
        _tdSDK = [ThinkingAnalyticsSDK startWithAppId:@"57e9f7c9078344c985c00f981c254bd4" withUrl:@"https://think.afunapp.com" withConfig:config];
        
        NSString *environment = @"debug";
#if (BUILD_VERSION == 0)
        environment = @"debug";
#elif (BUILD_VERSION == 1) // release包不上线，打开这些选项可以帮助分析
        environment = @"release";
#elif (BUILD_VERSION == 2)
        environment = @"production";
#endif
        
        NSString *device = [UIDevice deviceModelName];
        [_tdSDK registerDynamicSuperProperties:^NSDictionary<NSString *,id> * _Nonnull{
            return @{
                @"app_environment" : environment,
                @"app_channel" : @"appstore",
                @"device" : device,
                @"abtest_group" : WPAccountCacheI.abTestGroup? WPAccountCacheI.abTestGroup : @""
            };
        }];
        [_tdSDK enableAutoTrack:ThinkingAnalyticsEventTypeAppViewCrash properties:@{
            @"app_environment" : environment,
            @"app_channel" : @"appstore",
            @"device" : device,
        }];
        
        [_tdSDK enableAutoTrack:ThinkingAnalyticsEventTypeAppStart properties:@{
            @"app_environment" : environment,
            @"app_channel" : @"appstore",
            @"device" : device,
        }];
    }
    return self;
}

- (void)trackEvent:(NSString *)eventId params:(NSDictionary *)params {
    [self.tdSDK track:eventId properties:params];
}

- (void)login {
    [self.tdSDK logout];
    NSString *accountId = SNKAccountUserM.userId;
    if (SNKStringIsEmpty(accountId)) {
        accountId = SNKAccountManagerM.deviceId;
    }
    [self.tdSDK login:accountId];
}

#pragma mark - public

+ (void)login {
    [[self sharedInstance] login];
}


+ (void)trackEvent:(NSString *)eventId params:(NSDictionary *)params {
    [[self sharedInstance] trackEvent:eventId params:params];
}

@end
