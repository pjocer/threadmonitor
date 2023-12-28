//
//  WPZombie.h
//  ZombieSniffer
//
//  Created by karos li on 2023/5/14.
//

#import <Foundation/Foundation.h>

/// 僵尸对象
@interface WPZombie : NSProxy

@property (nonatomic, assign) Class realClass;
@property (nonatomic, strong) NSArray<NSNumber *> *callStackAddresses;

@end
