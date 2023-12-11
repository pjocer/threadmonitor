//
//  back_trace.h
//  Pods-SNKThreadMonitor_Example
//
//  Created by Jocer on 2023/8/16.
//

#ifndef back_trace_h
#define back_trace_h

#define MAX_CALL_STACK_SIZE 128

#import <mach/mach.h>
#import <stdio.h>

typedef struct {
    const uintptr_t *fp; //stp fp, lr, ...
    const uintptr_t lr;
} pj_stack_frame_fp_lr_t;

typedef struct {
    uint64_t addr;
    uint64_t lr_addr;
    uint64_t offset;
    const char *symbol;
    const char *machOName;
    uint64_t machImageHeader;
} pj_func_info_t;

typedef struct {
    pj_func_info_t *stacks;
    int allocLength;
    int length;
} pj_call_stack_info_t;

typedef struct {
    const struct mach_header *header;
    const char *name;
    uintptr_t slide;
} pj_mach_header_t;

typedef struct {
    pj_mach_header_t *array;
    uint32_t allocLength;
} pj_mach_header_arr_t;

void callStackOfSymbol(uintptr_t *pcArr, int arrLen, pj_call_stack_info_t *csInfo);

int getMachineContext(thread_t thread, _STRUCT_MCONTEXT64 *machineContext);

int readFPMemory(const void *fp, const void *dst, const vm_size_t len);

void freeMemory(pj_call_stack_info_t *csInfo);

#endif /* back_trace_h */
