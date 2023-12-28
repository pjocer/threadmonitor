//
//  WPZombieException.h
//  SnakeGameSingle
//
//  Created by karos li on 2023/5/17.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 对象 dealloc 时的自定义异常堆栈，然后抛出异常，第三方崩溃收集框架可以获取改崩溃
@interface WPZombieDeallocException : NSException
@property (nonatomic, strong) NSArray<NSNumber *> *customStackReturnAddresses;
@property (nonatomic, strong) NSString *customDescription;
@end
