//
//  SNKAPMMemoryItem.m
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/24.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "SNKAPMMemoryItem.h"
#import <mach/mach.h>

@interface SNKAPMMemoryItem()

@property(nonatomic, strong) NSMutableDictionary *memoryDict;

@end

@implementation SNKAPMMemoryItem

- (instancetype)init {
    if (self = [super init]) {
        self.memoryDict = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)setMemoryWithKey:(NSString *)key {
    if (SNKStringIsEmpty(key)) return;
    self.memoryDict[key] = @([self.class currentMemory]);
}

- (NSUInteger)memoryWithKey:(NSString *)key {
    if (SNKStringIsEmpty(key)) return 0;
    return [self.memoryDict[key] unsignedIntegerValue];
}

- (NSUInteger)startMemory {
    return [self memoryWithKey:SNKAPMMemoryItemStartKey];
}

- (NSUInteger)endMemory {
    return [self memoryWithKey:SNKAPMMemoryItemEndKey];
}

// 单位是byte
+ (NSUInteger)currentMemory {
    int64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
        return memoryUsageInByte;
    }
    return 0;
}

@end
