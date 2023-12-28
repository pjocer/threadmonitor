//
//  SNKProtectCache.h
//  SnakeGameSingle
//
//  Created by karos li on 2022/3/30.
//  Copyright © 2022 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>

/// patch 脚本下载和缓存
@interface SNKProtectCache : NSObject

+ (instancetype)sharedInstance;

- (void)downloadPatchWithLink:(NSString *)patchLink version:(NSString *)patchVersion completeBlock:(void(^)(NSString *filepath, NSError *error))completeBlock;

@end

