//
//  SNKAPMANRTracker.m
//  SnakeGameSingle
//
//  Created by 刘志华 on 2023/7/27.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "SNKAPMANRTracker.h"
#import "SentryDependencyContainer.h"
#import "SentryANRTracker.h"

@interface SNKAPMANRTracker ()<SentryANRTrackerDelegate>

@property (nonatomic, strong) SentryANRTracker *tracker;

@end

@implementation SNKAPMANRTracker

- (void)startANRCapture {
    if (_tracker == nil) {
        [self.tracker addListener:self];
    }
}

- (void)endANRCapture {
    [self.tracker clear];
    self.tracker = nil;
}

- (void)anrDetected {
    !self.anrDetectedBlock ?: self.anrDetectedBlock();
}

- (void)anrStopped {
    
}

- (void)dealloc {
    [self endANRCapture];
}

- (SentryANRTracker *)tracker {
    if (!_tracker) {
        _tracker =
            [SentryDependencyContainer.sharedInstance getANRTracker:2];
    }
    return _tracker;
}


@end
