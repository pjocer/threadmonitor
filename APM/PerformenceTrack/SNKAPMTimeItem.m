//
//  SNKAPMTimeItem.m
//  SnakeGameSingle
//
//  Created by aksskas on 2023/7/21.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//

#import "SNKAPMTimeItem.h"

@interface SNKAPMTimeItemInfo : NSObject

@property(nonatomic, strong) NSString *curKey;

@property(nonatomic, strong) NSString *toKey;

@property(nonatomic, assign) NSInteger curTimestamp;

@end

@implementation SNKAPMTimeItemInfo

@end

@interface SNKAPMTimeItem()

@property(nonatomic, strong) NSMutableDictionary *timeDict;

@property(nonatomic, strong) NSMutableDictionary<NSString *,SNKAPMTimeItemInfo *> *infoDic;

@end

@implementation SNKAPMTimeItem


- (instancetype)init {
    if (self = [super init]) {
        self.timeDict = [NSMutableDictionary dictionary];
        self.infoDic = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setTimeWithKey:(NSString *)key {
    if (SNKStringIsEmpty(key)) return;
    NSUInteger time = NSProcessInfo.processInfo.systemUptime * 1000l;
    self.timeDict[key] = @(time);
}

- (NSUInteger)timeWithKey:(NSString *)key {
    if (SNKStringIsEmpty(key)) return 0;
    return [self.timeDict[key] unsignedIntegerValue];
}

- (NSUInteger)startTime {
    return [self timeWithKey:SNKAPMTimeItemStartKey];
}

- (NSUInteger)endTime {
    return [self timeWithKey:SNKAPMTimeItemEndKey];
}

- (void)addkey:(NSString *)key toKey:(NSString *)toKey {
    if (SNKStringIsEmpty(key)) {
        return;
    }
    NSUInteger time = NSProcessInfo.processInfo.systemUptime * 1000l;
    SNKAPMTimeItemInfo *info = self.infoDic[key];
    if (!info) {
        info = [[SNKAPMTimeItemInfo alloc] init];
    }
    info.curKey = key;
    if (self.infoDic[toKey]) {
        info.toKey = toKey;
    }
    info.curTimestamp = time;
    self.infoDic[key] = info;
}

- (NSDictionary *)genTimeDic {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSUInteger endTime = NSProcessInfo.processInfo.systemUptime * 1000l;
    WEAKSELF
    [self.infoDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, SNKAPMTimeItemInfo * _Nonnull obj, BOOL * _Nonnull stop) {
        NSUInteger deltaTime = 0;
        if (obj.toKey) {
            SNKAPMTimeItemInfo *toItemInfo = weakSelf.infoDic[obj.toKey];
            deltaTime = obj.curTimestamp - toItemInfo.curTimestamp;
        }else{
            deltaTime = endTime - obj.curTimestamp;
        }
        dic[key] = @(deltaTime);
    }];
    return dic;
}

@end
