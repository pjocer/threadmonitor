//
//  NSException+WPZombie.m
//  SnakeGameSingle
//
//  Created by karos li on 2023/10/19.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "NSException+WPZombie.h"
#import "SNKSwizzle.h"

@implementation NSException (WPZombie)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classInstanceMethodSwizzle(self, @selector(callStackReturnAddresses), @selector(wpzombie_callStackReturnAddresses), NULL);
    });
}

- (void)setCustomStackReturnAddresses:(NSArray<NSNumber *> *)customStackReturnAddresses {
    objc_setAssociatedObject(self, @selector(customStackReturnAddresses), customStackReturnAddresses, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray<NSNumber *> *)customStackReturnAddresses {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSArray<NSNumber *> *)wpzombie_callStackReturnAddresses {
    if (self.customStackReturnAddresses.count > 0) {
        return self.customStackReturnAddresses;
    }
    
    return [self wpzombie_callStackReturnAddresses];
}

@end
