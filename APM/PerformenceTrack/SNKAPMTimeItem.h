//
//  SNKAPMTimeItem.h
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/21.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SNKAPMTimeItemStartKey @"SNKAPM_START_TIME"
#define SNKAPMTimeItemEndKey @"SNKAPM_END_TIME"

@interface SNKAPMTimeItem : NSObject

- (void)setTimeWithKey:(NSString *)key;
- (NSUInteger)timeWithKey:(NSString *)key;

- (NSUInteger)startTime;

- (NSUInteger)endTime;

- (void)addkey:(NSString *)key toKey:(NSString *)toKey;

- (NSDictionary *)genTimeDic;

@end
