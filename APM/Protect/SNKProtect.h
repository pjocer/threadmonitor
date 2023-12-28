//
//  SNKProtect.h
//  SnakeGameSingle
//
//  Created by karos li on 2022/3/30.
//  Copyright © 2022 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SNKAPMConfig;
@interface SNKProtect : NSObject
/// 开始保护
+ (void)startProtect:(SNKAPMConfig *)config completeBlock:(void(^)(NSError *error))completeBlock;
/// 当前热修复版本，用于通用参数，和通用埋点参数
+ (NSString *)curPatchVersion;

@end
