//
//  lock_checker.m
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/22.
//

#import "lock_checker.h"
#import "mach.h"
#import "context_helper.h"
#import "lock_indicator.h"
#import <dlfcn.h>
#import <mach/thread_act.h>
#import "SNKBackTrace.h"

void mach_check_thread_dead_lock(thread_t thread, NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic) {
#ifndef __i386__
    thread_extended_info_data_t threadInfoData;
    mach_msg_type_number_t threadInfoCount = THREAD_EXTENDED_INFO_COUNT;
    thread_identifier_info_data_t threadIDData;
    mach_msg_type_number_t threadIDDataCount = THREAD_IDENTIFIER_INFO_COUNT;
    if (thread_info(thread, THREAD_EXTENDED_INFO, (thread_info_t)&threadInfoData, &threadInfoCount) == KERN_SUCCESS &&
        thread_info(thread, THREAD_IDENTIFIER_INFO, (thread_info_t)&threadIDData, &threadIDDataCount) == KERN_SUCCESS) {
        uint64_t thread_id = threadIDData.thread_id;
        integer_t cpu_usage = threadInfoData.pth_cpu_usage;
        integer_t run_state = threadInfoData.pth_run_state;
        integer_t flags = threadInfoData.pth_flags;
        if ((run_state & TH_STATE_WAITING) && (flags & TH_FLAGS_SWAPPED) && cpu_usage == 0) {
            checkMainEmptyCPUUsageWithWapped(thread, thread_id, threadWaitDic);
        }
        //主线程的 CPU 占用一直很高 ，处于运行的状态，那么就应该怀疑主线程是否存在一些死循环等 CPU 密集型的任务。
        if ((run_state & TH_STATE_RUNNING) && cpu_usage > 800) {
            //怀疑死循环
            NSLog(@"怀疑死循环:%llu",thread_id);
        }
    }
#endif
}
// 主线程CPU占用很高，运行状态
void checkMainHighCPUUsage(thread_t thread, uint64_t thread_id , NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic) {
#ifndef __i386__
#endif
}
// 主线程CPU占用为0，等待状态且已被换出
void checkMainEmptyCPUUsageWithWapped(thread_t thread, uint64_t thread_id, NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic) {
#ifndef __i386__
    // 通过符号化判断它是否是一个锁等待的方法。
    _STRUCT_MCONTEXT machineContext;
    //通过 thread_get_state 获取完整的 machineContext 信息，包含 thread 状态信息
    mach_msg_type_number_t state_count = j_threadStateCountByCPU();
    kern_return_t kr = thread_get_state(thread, j_threadStateByCPU(), (thread_state_t)&machineContext.__ss, &state_count);
    if (kr != KERN_SUCCESS) {
        NSLog(@"Fail get thread: %u", thread);
        return;
    }
    //通过指令指针来获取当前指令地址
    SNKBackTrace *backTrace = [SNKBackTrace backTraceWith:thread deep:1];
    NSMutableArray *symbols = backTrace.symbols;
    for (int i = 0; i < symbols.count; i++) {
        const char *cString = [symbols[i] UTF8String];
        // https://github.com/apple-oss-distributions/libpthread/blob/d8c4e3c212553d3e0f5d76bb7d45a8acd61302dc/src/imports_internal.h#L47
        if (strcmp(cString, "__psynch_mutexwait") == 0) {
            // 认为`thread`正在等待锁
            uintptr_t firstParam = j_firstParamRegister(&machineContext);
            struct pthread_mutex_s *mutex = (struct pthread_mutex_s *)firstParam;
            uint32_t *tid = mutex->psynch.m_tid;
            uint64_t hold_lock_thread_id = *tid;
            //需要判断死锁
            if (hold_lock_thread_id > 0) {
                NSMutableArray *array = threadWaitDic[@(hold_lock_thread_id)];
                if (!array) {
                    array = [NSMutableArray array];
                }
                [array addObject:@(thread_id)];
                threadWaitDic[@(hold_lock_thread_id)] = array;
            }
            break;
        }
        
    }
    // TODO: 其他锁情况
    //
    //__psynch_rw_rdlock   ReadWrite lock
    //__psynch_rw_wrlock   ReadWrite lock
    //__ulock_wait         UnfariLock lock
    //_kevent_id           GCD lock
    
    // psynch_cvwait，semwait_signal，psynch_mutexwait，psynch_mutex_trylock，dispatch_sync_f_slow
#endif
}

BOOL checkIfIsCircleWithThreadWaitDic(NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic) {
#ifndef __i386__
    __block BOOL hasCircle = NO;
    NSMutableDictionary<NSNumber *,NSNumber *> *visited = [NSMutableDictionary dictionary];
    NSMutableArray *path = [NSMutableArray array];
    [threadWaitDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull hold_lock_thread_id, NSMutableArray<NSNumber *> * _Nonnull waitArray, BOOL * _Nonnull stop) {
        checkThreadIDWith(hold_lock_thread_id, threadWaitDic, visited, path, &hasCircle);
        if (hasCircle) {
            *stop = YES;
        }
    }];
    return hasCircle;
#endif
}

void checkThreadIDWith(NSNumber *threadID,
                       NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic,
                       NSMutableDictionary<NSNumber *,NSNumber *> *visited,
                       NSMutableArray *path,
                       BOOL *hasCircle) {
#ifndef __i386__
    if (visited[threadID]) {
        *hasCircle = YES;
        NSUInteger index = [path indexOfObject:threadID];
        path = [[path subarrayWithRange:NSMakeRange(index, path.count - index)] mutableCopy];
    }
    if (*hasCircle) {
        return;
    }
    
    visited[threadID] = @1;
    [path addObject:threadID];
    NSMutableArray *array = threadWaitDic[threadID];
    if (array.count) {
        for (NSNumber *next in array) {
            checkThreadIDWith(next, threadWaitDic, visited, path, hasCircle);
        }
    }
    [visited removeObjectForKey:threadID];
#endif
}
