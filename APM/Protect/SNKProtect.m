//
//  SNKProtect.m
//  SnakeGameSingle
//
//  Created by karos li on 2022/3/30.
//  Copyright © 2022 WepieSnakeGame. All rights reserved.
//

#import "SNKProtect.h"
#import "SNKCrashlyticsManger.h"
#if TARGET_IPHONE_SIMULATOR
#else
#import <WPFix/WPFix.h>
#endif
#import "SNKProtectCache.h"
#import "SNKAPMConfig.h"

static NSString * const kSNKTrackProtectIssueErrorLog = @"kSNKTrackProtectIssueErrorLog";

@implementation SNKProtect

+ (void)startProtect:(SNKAPMConfig *)config completeBlock:(void(^)(NSError *error))completeBlock {
    
#if TARGET_IPHONE_SIMULATOR
    !completeBlock ?: completeBlock(nil);
    return;
#else

    
    // 设置日志处理
    [WPFix setLuaLogHandler:^(NSString *log) {
        NSString *tagLog = [NSString stringWithFormat:@"[保护][统一日志打印] %@", log];
        NSLog(@"%@", tagLog);
    }];

#ifdef DEBUG
//    [self startLocalProtectDev];
//    !completeBlock? :completeBlock(nil);
//    return;
#endif
    
    if (SNKStringIsEmpty(config.patchLink) ) {
        !completeBlock ?: completeBlock(nil);
        return;
    }

    // 设置错误处理
    [WPFix setLuaErrorHandler:^(NSString *error) {
        NSString *tagError = [NSString stringWithFormat:@"[保护][统一错误拦截] %@", error];
        NSLog(@"%@", tagError);
        
        [SNKCrashlyticsManger captureCustomExceptionWithName:kSNKTrackProtectIssueErrorLog reason:tagError stackTrace:nil];
    }];
    
    NSString *version = [NSString stringWithFormat:@"%@_%@", [UIDevice appVersion], config.patchVersion ? config.patchVersion : @""];
    [[SNKProtectCache sharedInstance] downloadPatchWithLink:config.patchLink version:version completeBlock:^(NSString *filepath, NSError *error) {
        if (error) {
            !completeBlock? :completeBlock(error);
        } else {
            // 执行修复脚本
            if ([self protectWithPath:filepath]) {
                // 进入这里说明热修复失败，脚本存在问题
                !completeBlock? :completeBlock([NSError errorWithDomain:@"ProtectIssue" code:-1 userInfo:@{NSLocalizedDescriptionKey : @"protect failed"}]);
            } else {
                // 热修复成功时，更新下脚本版本
                patch_version = version;
                !completeBlock? :completeBlock(nil);
            }
        }
    }];
#endif
    
}

static NSString *patch_version = @"";
+ (NSString *)curPatchVersion {
    return patch_version;
}

+ (void)startLocalProtectDev {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"protect" ofType:@"txt"];
    [self protectWithPath:filepath];
}

+ (int)protectWithPath:(NSString *)filepath {
#if TARGET_IPHONE_SIMULATOR
    return 0;
#else
#ifdef DEBUG
    // 添加调试
    [WPFix addExtensionDebug];
#endif
    // 启动
    [WPFix start];
    // 执行修复脚本
    return [WPFix runLuaFile:filepath];
#endif
}

@end
