//
//  NSException+WPZombie.h
//  SnakeGameSingle
//
//  Created by karos li on 2023/10/19.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSException (WPZombie)

/// 自定义异常堆栈，用于给三方crash框架收集 dealloc 堆栈
@property (nonatomic, strong) NSArray<NSNumber *> *customStackReturnAddresses;

@end

