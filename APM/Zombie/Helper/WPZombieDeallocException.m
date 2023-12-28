//
//  WPZombieException.m
//  SnakeGameSingle
//
//  Created by karos li on 2023/5/17.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "WPZombieDeallocException.h"

@implementation WPZombieDeallocException

- (NSArray *)callStackReturnAddresses {
    if (self.customStackReturnAddresses) {// 返回自定义的堆栈地址
        return self.customStackReturnAddresses;
    }
    
    return [super callStackReturnAddresses];
}

- (NSString *)description {
    if (self.customDescription) {
        return self.customDescription;
    }
    
    return [super description];
}

@end
