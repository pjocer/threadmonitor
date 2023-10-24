//
//  mach_utils.c
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/23.
//

#import "mach.h"
#import <mach/task.h>
#import <mach/mach_init.h>
#import <mach/thread_act.h>
#import <mach/mach_error.h>
#import <dispatch/dispatch.h>
#import <sys/param.h>

static inline int copySafely(const void* restrict const src, void* restrict const dst, const int byteCount) {
    vm_size_t bytesCopied = 0;
    kern_return_t result = vm_read_overwrite(mach_task_self(),
                                             (vm_address_t)src,
                                             (vm_size_t)byteCount,
                                             (vm_address_t)dst,
                                             &bytesCopied);
    if(result != KERN_SUCCESS) {
        return 0;
    }
    return (int)bytesCopied;
}
static char pj_memory_buffer[10240];
static inline bool is_memory_readable(const void* const memory, const int byteCount) {
    const int testBufferSize = sizeof(pj_memory_buffer);
    int bytesRemaining = byteCount;
    while(bytesRemaining > 0) {
        int bytesToCopy = bytesRemaining > testBufferSize ? testBufferSize : bytesRemaining;
        if(copySafely(memory, pj_memory_buffer, bytesToCopy) != bytesToCopy) {
            break;
        }
        bytesRemaining -= bytesToCopy;
    }
    return bytesRemaining == 0;
}

bool mach_thread_get_queue_name(struct thread_identifier_info info, char* const buffer, int bufLength) {
    thread_identifier_info_t idInfo = &info;
    if(!is_memory_readable(idInfo, sizeof(*idInfo))) {
        printf("Invalid thread identifier info %p", idInfo);
        return false;
    }
    dispatch_queue_t* dispatch_queue_ptr = (dispatch_queue_t*)idInfo->dispatch_qaddr;
    if(!is_memory_readable(dispatch_queue_ptr, sizeof(*dispatch_queue_ptr))) {
        printf("Invalid dispatch queue pointer %p", dispatch_queue_ptr);
        return false;
    }
    //thread_handle shouldn't be 0 also, because
    //identifier_info->dispatch_qaddr =  identifier_info->thread_handle + get_dispatchqueue_offset_from_proc(thread->task->bsd_info);
    if(dispatch_queue_ptr == NULL || idInfo->thread_handle == 0 || *dispatch_queue_ptr == NULL) {
        // 无队列
        return false;
    }
    
    dispatch_queue_t dispatch_queue = *dispatch_queue_ptr;
    const char* queue_name = dispatch_queue_get_label(dispatch_queue);
    if(queue_name == NULL) {
        printf("Error while getting dispatch queue name : %p", dispatch_queue);
        return false;
    }
    int length = (int)strlen(queue_name);
    int iLabel;
    for(iLabel = 0; iLabel < length + 1; iLabel++) {
        if(queue_name[iLabel] < ' ' || queue_name[iLabel] > '~') {
            break;
        }
    }
    // 确保结束符为null
    if(queue_name[iLabel] != 0) {
        printf("Queue label contains invalid chars");
        return false;
    }
    bufLength = MIN(length, bufLength - 1);
    strncpy(buffer, queue_name, bufLength);
    buffer[bufLength] = 0;
    return true;
}


bool generate_basic_info(thread_act_t mch_port, thread_basic_info_data_t *basicInfo) {
    mach_msg_type_number_t basicInfoCount = THREAD_BASIC_INFO_COUNT;
    kern_return_t kr = thread_info(mch_port, (thread_flavor_t)THREAD_BASIC_INFO, (thread_info_t)basicInfo, &basicInfoCount);
    if (kr != KERN_SUCCESS) {
        // TODO: 错误处理
        fprintf(stderr, "Error getting thread basic info: %s\n", mach_error_string(kr));
        return false;
    }
    return true;
}

bool generate_identifier_info(thread_act_t mch_port, thread_identifier_info_data_t *identifierInfo) {
    mach_msg_type_number_t identifierInfoCount = THREAD_IDENTIFIER_INFO_COUNT;
    kern_return_t kr = thread_info(mch_port, (thread_flavor_t)THREAD_IDENTIFIER_INFO, (thread_info_t)identifierInfo, &identifierInfoCount);
    if (kr != KERN_SUCCESS) {
        // TODO: 错误处理
        fprintf(stderr, "Error getting thread identifier info: %s\n", mach_error_string(kr));
        return false;
    }
    return true;
}
bool mach_thread_get_name(const thread_t thread, char* const buffer, int bufLength) {
    const pthread_t pthread = pthread_from_mach_thread_np((thread_t)thread);
    return pthread_getname_np(pthread, buffer, (unsigned)bufLength) == 0;
}
bool generate_extended_info(thread_act_t mch_port, thread_extended_info_data_t *extendedInfo) {
    mach_msg_type_number_t extendedInfoCount = THREAD_EXTENDED_INFO_COUNT;
    kern_return_t kr = thread_info(mch_port, (thread_flavor_t)THREAD_EXTENDED_INFO, (thread_info_t)extendedInfo, &extendedInfoCount);
    if (kr != KERN_SUCCESS) {
        // TODO: 错误处理
        fprintf(stderr, "Error getting thread extended info: %s\n", mach_error_string(kr));
        return false;
    }
    return true;
}

bool generate_io_stats_info(thread_act_t mch_port, thread_info_data_t *ioStatsInfo) {
    return false;
}

bool get_thread_list(thread_act_array_t *list, mach_msg_type_number_t *count) {
    int32_t kr = task_threads(mach_task_self_, list, count);
    if (kr != KERN_SUCCESS) {
        // TODO: 错误处理
        fprintf(stderr, "Error getting thread list: %s\n", mach_error_string(kr));
        return false;
    }
    return true;
}

void deallocate_thread_list(thread_act_array_t list, mach_msg_type_number_t count) {
    kern_return_t kr = KERN_SUCCESS;

    // 使用 vm_deallocate 函数释放内存
    kr = vm_deallocate(mach_task_self(), (vm_address_t)list, count * sizeof(thread_t));

    if (kr != KERN_SUCCESS) {
        printf("Error deallocating thread list memory: %s\n", mach_error_string(kr));
    }
}

uintptr_t thread_self(void) {
    thread_t thread_self = mach_thread_self();
    mach_port_deallocate(mach_task_self(), thread_self);
    return thread_self;
}
