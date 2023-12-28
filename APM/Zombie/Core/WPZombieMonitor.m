//
//  WPZombieMonitor.m
//  ZombieSniffer
//
//  Created by karos li on 2023/5/15.
//

#if __has_feature(objc_arc)
#error This file must be compiled without ARC. Use -fno-objc-arc flag.
#endif

#import "WPZombieMonitor.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import <dispatch/dispatch.h>
#import <mach/mach.h>
#import <pthread.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#import <Sentry/Sentry.h>
#import "wpdsqueue.h"
#import "WPZombie.h"

// 超过最大内存占用或者最大对象个数，都需要释放 zombie 对象
/// 默认最大 zombie 内存大小，10M
static NSInteger kDefaultMaxOccupyMemorySize = 10 * 1024 * 1024;
/// 最大 zombie 个数
static NSInteger kDefaultMaxOccupyZombieCount = 5000;

/// 判断指针是否是 tag pointer
#define TAG_MASK (1ULL << 63)
static inline bool wpzombie_objc_isTaggedPointer(const void * _Nullable ptr) {
    return (((uintptr_t)ptr) & TAG_MASK) != 0;
}

/// 方法替换
void wpzombie_replaceSelectorWithSelector(Class clazz,
                                 SEL selector,
                                 SEL replacementSelector) {
    Method replacementSelectorMethod = class_getInstanceMethod(clazz, replacementSelector);
    class_replaceMethod(clazz,
                        selector,
                        method_getImplementation(replacementSelectorMethod),
                        method_getTypeEncoding(replacementSelectorMethod));
}

@interface NSObject (WPZombieMonitor)
- (void)wpzombie_originalDealloc;
- (void)wpzombie_newDealloc;
@end

@interface WPZombieMonitor ()
{
    struct WPDSQueue *_delayFreeQueue;// 循环队列，用于存储 zombie 对象的地址，然后在合适的时机释放 zombie 对象
    NSUInteger _occupyMemorySize;// 占用内存大小，包括延迟释放对象内存大小和释放栈大小
    BOOL _isInDetecting;
//    CFMutableSetRef _customRegisteredClasses;
    NSSet<NSString*> *_whiteList;// 在白名单策略下，只 hook 白名单里的类
    NSSet<NSString*> *_forceFilterList;// 任何策略下，都需要先强制过滤掉这些
    NSSet<NSString*> *_forceFilterSystemList;// 系统过滤列表的前缀字符串
}

@end

@implementation WPZombieMonitor

@dynamic whiteList;
@dynamic forceFilterList;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static WPZombieMonitor *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [WPZombieMonitor new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.maxOccupyMemorySize = kDefaultMaxOccupyMemorySize;
        self.traceDeallocStack = YES;
        self.strategy = WPZombieDetectStrategyCustomObjectOnly;
        [self initForceFilterSystemList];
    }
    return self;
}

- (void)dealloc {
    [self stopMonitor];
    [super dealloc];
}

#pragma mark - 公共方法
- (void)startMonitor {
    @synchronized(self) {
        if (_isInDetecting) {
            return;
        }
        _delayFreeQueue = wp_ds_queue_create((uint32_t)kDefaultMaxOccupyZombieCount);// 可以存多少僵尸对象
        _isInDetecting = YES;
//        [self getCustomClass];// 用不上，先去掉
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarningNotificationHandle:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        // 用 wpzombie_originalDealloc 记录原始 dealloc 的 IMP
        wpzombie_replaceSelectorWithSelector([NSObject class], @selector(wpzombie_originalDealloc), sel_registerName("dealloc"));
        // 把 NSObject 的 dealloc 方法替换成新的方法实现
        wpzombie_replaceSelectorWithSelector([NSObject class], sel_registerName("dealloc"), @selector(wpzombie_newDealloc));
    }
}

- (void)stopMonitor {
    @synchronized(self) {
        if (!_isInDetecting) {
            return;
        }
        wpzombie_replaceSelectorWithSelector([NSObject class], sel_registerName("dealloc"), @selector(wpzombie_originalDealloc));
        void *item = wp_ds_queue_try_get(_delayFreeQueue);
        while (item) {
            [self freeZombieObject:item];
            item = wp_ds_queue_try_get(_delayFreeQueue);
        }
        _isInDetecting = NO;
        wp_ds_queue_close(_delayFreeQueue);
        wp_ds_queue_free(_delayFreeQueue);
        _delayFreeQueue = NULL;
//        if (_customRegisteredClasses) {
//            CFRelease(_customRegisteredClasses);
//            _customRegisteredClasses = NULL;
//        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

#pragma mark - hook dealloc
- (void)hookedDealloc:(__unsafe_unretained id)obj {
    if ([self shouldDetect:obj]) {
        void *p = (__bridge void *)obj;
        size_t memSize = malloc_size(p);// 目标对象系统分配的实际内存大小
        size_t zombieInstanceSize = class_getInstanceSize([WPZombie class]);// zombie 对象实例占用的内存大小
        if (memSize < zombieInstanceSize) {// 有足够的空间才继续走
            [self callOriginDealloc:obj];
            return;
        }
        
        Class origClass = object_getClass(obj);
        
        //析构对象，释放成员变量，但并没有释放对象本身
        objc_destructInstance(obj);
        
        //填充0x55能稍微提升一些crash率
        memset(p, 0x55, memSize);
        memset(p, 0x00, zombieInstanceSize);
        // 修改对象的 isa 指针
        object_setClass(obj, [WPZombie class]);
        
        WPZombie *zombieObject = (WPZombie*)p;
        zombieObject.realClass = origClass;
        
        if (self->_traceDeallocStack) {// 需要记录对象释放的堆栈
            zombieObject.callStackAddresses = [NSThread callStackReturnAddresses];
            memSize += zombieObject.callStackAddresses.count * 8;// 里面存的long
        }
        
        [self freeMemoryIfNeed];
        
        // 增加内存占用大小
        __sync_fetch_and_add(&_occupyMemorySize, (int)memSize);
        // 入队并尝试取出第一个 zombie 对象
        void *item = wp_ds_queue_put_pop_first_item_if_need(_delayFreeQueue, p);
        if (item) {
            [self freeZombieObject:item];
        }
    } else {
        [self callOriginDealloc:obj];
    }
}

// 调用对象的原始dealloc方法
- (void)callOriginDealloc:(__unsafe_unretained id)obj {
    Class klass = object_getClass(obj);
    SEL savedOriginSelector = @selector(wpzombie_originalDealloc);
    Method originDeallocMethod = class_getInstanceMethod(klass, savedOriginSelector);
    if (originDeallocMethod != NULL) {
        void (*originalDealloc)(__unsafe_unretained id, SEL) = (__typeof__(originalDealloc))method_getImplementation(originDeallocMethod);
        originalDealloc(obj, NSSelectorFromString(@"dealloc"));
    }
}

- (BOOL)shouldDetect:(__unsafe_unretained id)obj {
    if (wpzombie_objc_isTaggedPointer(obj)) {
        return NO;
    }
    
    Class aClass = object_getClass(obj);
    if (aClass == Nil) {
        return NO;
    }
    
    BOOL bShouldDetect = NO;
    
    @autoreleasepool {
        NSString *className = NSStringFromClass(aClass);
        
        for (NSString *prefix in _forceFilterSystemList) {
            if ([className hasPrefix:prefix]) {
                return NO;
            }
        }
        
        if ([_forceFilterList containsObject:className]) {
            return NO;
        }
        
        switch (_strategy) {
            case WPZombieDetectStrategyCustomObjectOnly:
//                bShouldDetect = CFSetContainsValue(_customRegisteredClasses, (__bridge void*)aClass);
//                break;
                bShouldDetect = NO;
            case WPZombieDetectStrategyWhitelist:
                bShouldDetect = [_whiteList containsObject:className];
                break;
            case WPZombieDetectStrategyAll:
                bShouldDetect = YES;
                break;
            default:
                break;
        }
    }
    
    return bShouldDetect;
}

/// 获取自定义的类
//- (void)getCustomClass {
//    _customRegisteredClasses = CFSetCreateMutable(NULL, 0, NULL);
//    unsigned int classCount = 0;
//    const char** classNames = objc_copyClassNamesForImage([[NSBundle mainBundle] executablePath].UTF8String,&classCount);
//    if (classNames) {
//        for (unsigned int i = 0; i < classCount; i++) {
//            const char *className = classNames[i];
//            Class aClass = objc_getClass(className);
//            CFSetAddValue(_customRegisteredClasses, (__bridge const void *)(aClass));
//        }
//        free(classNames);
//    }
//}

#pragma mark - 内存

- (void)freeMemoryIfNeed {
    if (_occupyMemorySize < _maxOccupyMemorySize) {
        return;
    }
    
    @synchronized(self) {
        if (_occupyMemorySize >= _maxOccupyMemorySize) {
            [self forceFreeMemory];
        }
    }
}

- (void)forceFreeMemory {
//    bool is_main_thread = strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0;
    uint32_t freeCount = 0;
    // 同一时间最大释放次数
    int queue_length = wp_ds_queue_length(_delayFreeQueue);
    int max_free_count_one_time = queue_length / 5;
    void *item = wp_ds_queue_try_get(_delayFreeQueue);
    while (item && freeCount < max_free_count_one_time) {
        [self freeZombieObject:item];
        item = wp_ds_queue_try_get(_delayFreeQueue);
        ++freeCount;
    }
}

- (void)freeZombieObject:(void *)obj {
    WPZombie *zombieObject = (__bridge WPZombie*)obj;
    size_t zombieObjectSize = malloc_size(obj);
    size_t total_size = zombieObjectSize;
    if (zombieObject.callStackAddresses) {// 需要释放记录堆栈的数组
        total_size += zombieObject.callStackAddresses.count * 8;
    }
    
    // 析构成员变量
    objc_destructInstance(obj);
    // MRC 下需要手动置空
    zombieObject.realClass = nil;
    zombieObject.callStackAddresses = nil;
    // 释放对象占用的实际内存
    free(obj);
    // 减小内存占用大小
    __sync_fetch_and_sub(&_occupyMemorySize, (int)(total_size));
}

- (void)memoryWarningNotificationHandle:(NSNotification*)notification {
    [self forceFreeMemory];
}

#pragma mark - getter & setter

- (NSArray<NSString*>*)whiteList {
    return [_whiteList allObjects];
}

- (void)setWhiteList:(NSArray<NSString *> *)whiteList {
    _whiteList = [[NSSet alloc] initWithArray:whiteList];
}

- (NSArray<NSString*>*)forceFilterList {
    return [_forceFilterList allObjects];
}

- (void)setForceFilterList:(NSArray<NSString *> *)filterList {
    _forceFilterList = [[NSSet alloc] initWithArray:filterList];
}

- (void)initForceFilterSystemList {
    _forceFilterSystemList = [[NSSet alloc] initWithArray:@[
        @"OS_",
        @"RBS",
        @"NSXPC",
        @"_NSXPC",
        @"nw_",
    ]];
    
    /**
     还有很多，列不全，还是使用前缀判断
     // 跨进程通信
     @"OS_xpc_payload",
     @"OS_xpc_serializer",
     @"OS_xpc_data",
     @"OS_xpc_string",
     @"OS_xpc_pointer",
     @"OS_xpc_dictionary",
     @"OS_xpc_uuid",
     @"OS_xpc_array",
     @"OS_xpc_uint64",
     @"OS_xpc_double",
     @"OS_dispatch_data",
     @"OS_voucher",
     @"OS_dnssd_getaddrinfo_result",
     @"RBSXPCMessageContext",
     @"RBSXPCCoder",
     @"RBSInheritanceChangeSet",
     @"RBSXPCMessage",
     @"RBSXPCMessageReply",
     @"RBSInheritance",
     @"RBSAssertionIdentifier",
     @"RBSAssertion",
     @"NSXPCDecoder",
     @"_NSXPCConnectionExpectedReplyInfo",
     // 网络请求
     @"OS_nw_frame",
     @"OS_nw_array",
     @"nw_read_request",
     @"nw_association",
     */
}

@end

@implementation NSObject (WPZombieMonitor)
- (void)wpzombie_originalDealloc {
    //placeholder for original dealloc
}
- (void)wpzombie_newDealloc {
    [[WPZombieMonitor sharedInstance] hookedDealloc:self];
}
@end
