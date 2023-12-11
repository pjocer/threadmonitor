//
//  monitor.m
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/17.
//

#import "posix.h"
#import <pthread/introspection.h>
#import <mach/mach_error.h>

int pj_introspection_setspecific_np(pthread_t thread, pthread_key_t key, const void * _Nullable value) {
    return pthread_introspection_setspecific_np(thread, key, value);
}

void * _Nullable pj_introspection_getspecific_np(pthread_t _Nonnull thread, pthread_key_t key) {
    return pthread_introspection_getspecific_np(thread, key);
}

void pj_specific_destructor(void *value) {
    free(value);
}

pthread_key_t createSpecificKey(void) {
    pthread_key_t key;
    pthread_key_create(&key, pj_specific_destructor);
    return key;
}

const bool getPOSIXThreadName(pthread_t thread, char *buffer, size_t bufferSize) {
    int kr = pthread_getname_np(thread, buffer, bufferSize);
    if (kr != KERN_SUCCESS) {
        fprintf(stderr, "Error getThreadName: %s\n", mach_error_string(kr));
    }
    return kr == KERN_SUCCESS ? true : false;
}

pthread_introspection_hook_t g_oldpthread_introspection_hook = NULL;
void snk_pthread_introspection_hook(unsigned int event, pthread_t thread, void *addr, size_t size) {
    if (MonitorS.callback != NULL)
        MonitorS.callback(event, thread, addr, size);
    if (g_oldpthread_introspection_hook != NULL)
        g_oldpthread_introspection_hook(event, thread, addr, size);
}

@interface instrospection_hook ()
@property (nonatomic, copy, readwrite, nullable) PI_HOOK_CALL callback;
@end

@implementation instrospection_hook
+ (instancetype)shared {
    static instrospection_hook *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [instrospection_hook new];
    });
    return instance;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        g_oldpthread_introspection_hook = pthread_introspection_hook_install(snk_pthread_introspection_hook);
    }
    return self;
}
- (void)setPthreadIntrospectionHookCallBack:(void (^)(SNKPthreadIntrospectionState, pthread_t, void * _Nonnull, size_t))callBack {
    self.callback = callBack;
}
- (void)uninstall {
    self.callback = NULL;
    g_oldpthread_introspection_hook = NULL;
}
@end
