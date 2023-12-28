//
//  SNKTDTracker.h
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/25.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SNKTDTrack(eventId, dict) [SNKTDTracker trackEvent:eventId params:dict]

/// 数数SDK打点，用于性能打点
@interface SNKTDTracker : NSObject

+ (void)login;

+ (void)trackEvent:(NSString *)eventId params:(NSDictionary *)params;

@end

