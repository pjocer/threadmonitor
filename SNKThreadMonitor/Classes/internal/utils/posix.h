//
//  monitor.h
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/17.
//

#import <Foundation/Foundation.h>
#import <stdbool.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_CLOSED_ENUM(int, SNKPthreadIntrospectionState) {
    // 创建
    SNKPthreadIntrospectionStateCreate = 1,
    // 开始
    SNKPthreadIntrospectionStateStart,
    // 结束
    SNKPthreadIntrospectionStateTerminate,
    // 销毁
    SNKPthreadIntrospectionStateDestroy
};

const bool getPOSIXThreadName(pthread_t thread, char *buffer, size_t bufferSize);

void pj_specific_destructor(void *value);

pthread_key_t createSpecificKey(void);

__API_AVAILABLE(macos(11.0), ios(14.0), tvos(14.0), watchos(7.0))
int pj_introspection_setspecific_np(pthread_t thread, pthread_key_t key, const void * _Nullable value) ;

__API_AVAILABLE(macos(11.0), ios(14.0), tvos(14.0), watchos(7.0))
void * _Nullable pj_introspection_getspecific_np(pthread_t _Nonnull thread, pthread_key_t key);

#define MonitorS [instrospection_hook shared]
typedef void(^PI_HOOK_CALL)(SNKPthreadIntrospectionState state, pthread_t thread, void *addr, size_t size);
@interface instrospection_hook : NSObject
@property (nonatomic, copy, readonly, nullable) PI_HOOK_CALL callback;
+ (instancetype)shared;
- (void)setPthreadIntrospectionHookCallBack:(PI_HOOK_CALL)callBack;
- (void)uninstall;
@end

NS_ASSUME_NONNULL_END
