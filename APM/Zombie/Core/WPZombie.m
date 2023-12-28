//
//  WPZombie.m
//  ZombieSniffer
//
//  Created by karos li on 2023/5/14.
//

#if __has_feature(objc_arc)
#error This file must be compiled without ARC. Use -fno-objc-arc flag.
#endif

#import "WPZombie.h"
#import "WPZombieMonitor.h"
#import "WPZombieDeallocException.h"
#import "WPZombieDynamicLinker.h"
#import "NSException+WPZombie.h"
#import <Sentry/Sentry.h>

@implementation WPZombie

- (BOOL)respondsToSelector: (SEL)aSelector {
    return [self.realClass instancesRespondToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector: (SEL)sel {
    return [self.realClass instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation: (NSInvocation *)invocation {
    [self handleZombieWithSelector:invocation.selector zombieStackArr:[NSThread callStackReturnAddresses] deallocStackArr:self.callStackAddresses];
}

#define WPZombieHandleZombie() [self handleZombieWithSelector:_cmd zombieStackArr:[NSThread callStackReturnAddresses] deallocStackArr:self.callStackAddresses]
- (Class)class {
    WPZombieHandleZombie();
    return nil;
}

- (BOOL)isEqual:(id)object {
    WPZombieHandleZombie();
    return NO;
}

- (NSUInteger)hash {
    WPZombieHandleZombie();
    return 0;
}

- (BOOL)isKindOfClass:(Class)aClass {
    WPZombieHandleZombie();
    return NO;
}

- (BOOL)isMemberOfClass:(Class)aClass {
    WPZombieHandleZombie();
    return NO;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    WPZombieHandleZombie();
    return NO;
}

- (BOOL)isProxy {
    WPZombieHandleZombie();
    return NO;
}

- (NSString *)description {
    WPZombieHandleZombie();
    return nil;
}

- (void)dealloc {
    WPZombieHandleZombie();
    [super dealloc];
}

- (instancetype)retain {
    WPZombieHandleZombie();
    return nil;
}

- (id)copy {
    WPZombieHandleZombie();
    return nil;
}

- (id)mutableCopy {
    WPZombieHandleZombie();
    return nil;
}

- (oneway void)release {
    WPZombieHandleZombie();
}

- (instancetype)autorelease {
    WPZombieHandleZombie();
    return nil;
}

#pragma mark - Private

- (void)handleZombieWithSelector:(SEL)selector zombieStackArr:(NSArray<NSNumber *> *)zombieStack deallocStackArr:(NSArray<NSNumber *> *)deallocStack
{
    NSString *className = NSStringFromClass(self.realClass);
    NSString *selectorName = NSStringFromSelector(selector);
    [self reportToSentry:className selectorName:selectorName zombieStackArr:zombieStack deallocStackArr:deallocStack];
    
    if ([WPZombieMonitor sharedInstance].handle) {
        [WPZombieMonitor sharedInstance].handle(className, self, selectorName, deallocStack, zombieStack);
    }
    
    if (deallocStack) {
        NSException *exception = [NSException exceptionWithName:@"DeallocZombieBadAddress" reason:[NSString stringWithFormat:@"DeallocStack Custom -[%@ %@]: message sent to deallocated instance: %p", className, selectorName, self] userInfo:nil];
        
        NSMutableArray *stacks = [NSMutableArray array];
        if (deallocStack) {
            [stacks addObjectsFromArray:deallocStack];
            [stacks addObject:[NSNumber numberWithUnsignedLongLong:1111111111]];// 用于把第一次释放和第二次释放隔离开，方便查看堆栈
            [stacks addObjectsFromArray:zombieStack];
            exception.customStackReturnAddresses = stacks;
        }
        
        @throw exception;
    } else {
        @throw [NSException exceptionWithName:@"ZombieBadAddress" reason:[NSString stringWithFormat:@"ZombieStack -[%@ %@]: message sent to deallocated instance: %p", className, selectorName, self] userInfo:nil];
    }
}

- (void)reportToSentry:(NSString *)className selectorName:(NSString *)selectorName zombieStackArr:(NSArray<NSNumber *> *)zombieStack deallocStackArr:(NSArray<NSNumber *> *)deallocStack {
    if (deallocStack) {// 记录对象释放时的堆栈
        
        // 获取镜像文件
        int image_count = wpzombie_sentrycrashdl_imageCount();
        WPZombieSentryCrashBinaryImage image_list[image_count];
        for (int index = 0; index < image_count; index++) {
            wpzombie_sentrycrashdl_getBinaryImage(index, &image_list[index]);
        }
        
        NSMutableArray<SentryThread *> *threads = [NSMutableArray array];
        // 记录触发 dealloc 对象的堆栈
        NSMutableArray<SentryFrame *> *deallocFrames = [NSMutableArray array];
        for (NSNumber *address in deallocStack) {
            uintptr_t instructionAddress = (uintptr_t)[address unsignedLongLongValue];
            WPZombieSentryCrashBinaryImage *image = NULL;
            wpzombie_sentrycrashdl_getBinaryImageOfAddress(instructionAddress, image_list, image_count, &image);
            SentryFrame *frame = [[SentryFrame alloc] init];
            frame.instructionAddress = wpzombie_formatHexAddress([NSNumber numberWithUnsignedLongLong:instructionAddress]);
            frame.imageAddress = wpzombie_formatHexAddress([NSNumber numberWithUnsignedLongLong:image->address]);
            frame.package = [NSString stringWithCString:image->name encoding:NSUTF8StringEncoding];
            [deallocFrames addObject:frame];
        }
        SentryStacktrace *deallocStacktrace = [[SentryStacktrace alloc] initWithFrames:deallocFrames registers:@{}];
        SentryThread *deallocThread = [[SentryThread alloc] initWithThreadId:@(0)];
        deallocThread.stacktrace = deallocStacktrace;
        deallocThread.current = [NSNumber numberWithBool:YES];
        deallocThread.crashed = @(YES);
        [threads addObject:deallocThread];
        
        // 记录触发 zombie 对象的堆栈
        NSMutableArray<SentryFrame *> *zombieFrames = [NSMutableArray array];
        for (NSNumber *address in zombieStack) {
            uintptr_t instructionAddress = (uintptr_t)[address unsignedLongLongValue];
            WPZombieSentryCrashBinaryImage *image = NULL;
            wpzombie_sentrycrashdl_getBinaryImageOfAddress(instructionAddress, image_list, image_count, &image);
            SentryFrame *frame = [[SentryFrame alloc] init];
            frame.instructionAddress = wpzombie_formatHexAddress([NSNumber numberWithUnsignedLongLong:instructionAddress]);
            frame.imageAddress = wpzombie_formatHexAddress([NSNumber numberWithUnsignedLongLong:image->address]);
            frame.package = [NSString stringWithCString:image->name encoding:NSUTF8StringEncoding];
            [zombieFrames addObject:frame];
        }
        SentryStacktrace *zombieStacktrace = [[SentryStacktrace alloc] initWithFrames:zombieFrames registers:@{}];
        SentryThread *zombieThread = [[SentryThread alloc] initWithThreadId:@(1)];
        zombieThread.stacktrace = zombieStacktrace;
        [threads addObject:zombieThread];
        
        SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentryLevelError];
        SentryException *sentryException = [[SentryException alloc] initWithValue:[NSString stringWithFormat:@"DeallocStack -[%@ %@]: message sent to deallocated instance: %p", className, selectorName, self] type:@"ZombieBadAddress"];
        sentryException.mechanism = [[SentryMechanism alloc] initWithType:@"ZombieBadAddress"];
        sentryException.stacktrace = deallocStacktrace;
        event.exceptions = @[ sentryException ];
        event.threads = threads;
        [SentrySDK captureEvent:event];
        sleep(2);// 尽量让事件存好
    }
}

@end
