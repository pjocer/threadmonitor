//
//  SNKAPMANRTracker.h
//  SnakeGameSingle
//
//  Created by 刘志华 on 2023/7/27.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SNKAPMANRTracker : NSObject

@property(nonatomic, copy) void (^anrDetectedBlock)();

- (void)startANRCapture;

- (void)endANRCapture;

@end

NS_ASSUME_NONNULL_END
