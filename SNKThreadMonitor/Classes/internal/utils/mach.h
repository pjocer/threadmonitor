//
//  mach_utils.h
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/23.
//

#ifndef mach_utils_h
#define mach_utils_h

#import <stdio.h>
#import <mach/mach_types.h>
#import <mach/message.h>
#import <mach/thread_info.h>
#ifdef __cplusplus
extern "C" {
#endif

#import <sys/types.h>
#import <stdbool.h>
#import <pthread.h>
#import <mach/mach.h>

typedef enum {
    // 运行中
    SNKThreadMachStateRunning = 1,
    // 已停止（执行pthread_exit后，线程进入停止状态，但线程所占系统资源可能会保留以便重新启动，对应的内省状态为terminate）
    SNKThreadMachStateStopped,
    // 等待中(阻塞或其它保活流程，可被中断，e.g SIGINT)
    SNKThreadMachStateWating,
    // 不可中断的等待
    SNKThreadMachStateUninterruptible,
    // 已终止（线程停止运行、所占资源全部释放，对应的内省状态为destroy）
    SNKThreadMachStateHalted
} SNKThreadMachState;

typedef enum {
    // 线程被交换，对应的内存资源及上下文信息被写入磁盘中的交换文件中，重启线程时会有额外的性能开销
    SNKThreadFlagsTypeSwapped = 0x1,
    // 空闲状态（对应SNKThreadMachStateWating）
    SNKThreadFlagsTypeIdle = 0x2,
    // 强制空闲（系统强制回收线程所占资源，一般发生在资源稀缺或系统优化时）
    SNKThreadFlagsTypeForcedIdle = 0x4,
} SNKThreadFlagsType;

uintptr_t thread_self(void);

bool mach_thread_get_name(const thread_t thread, char* const buffer, int bufLength);

bool mach_thread_get_queue_name(struct thread_identifier_info info, char* const buffer, int bufLength);

bool get_thread_list(thread_act_array_t *list, mach_msg_type_number_t *count);

void deallocate_thread_list(thread_act_array_t list, mach_msg_type_number_t count);

bool generate_basic_info(thread_act_t mch_port, thread_basic_info_data_t *basicInfo);

bool generate_identifier_info(thread_act_t mch_port,  thread_identifier_info_data_t *identifierInfo);

bool generate_extended_info(thread_act_t mch_port, thread_extended_info_data_t *extendedInfo);

bool generate_io_stats_info(thread_act_t mch_port, thread_info_data_t *ioStatsInfo);

#endif /* mach_utils_h */
