//
//  SNKAPMMemoryItem.h
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/24.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>


#define SNKAPMMemoryItemStartKey @"SNKAPM_START_MEMORY"
#define SNKAPMMemoryItemEndKey @"SNKAPM_END_MEMORY"

@interface SNKAPMMemoryItem : NSObject

- (void)setMemoryWithKey:(NSString *)key;
- (NSUInteger)memoryWithKey:(NSString *)key;

- (NSUInteger)startMemory;

- (NSUInteger)endMemory;


+ (NSUInteger)currentMemory;

@end

