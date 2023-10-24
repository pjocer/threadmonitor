//
//  SNKBackTrace.m
//  Pods-SNKThreadMonitor_Example
//
//  Created by Jocer on 2023/8/16.
//

#import "SNKBackTrace.h"
#import <dlfcn.h>
#import "back_trace.h"
#import <execinfo.h>
#import "context_helper.h"
#import "mach.h"

@interface SNKBackTrace()
@property (nonatomic, readwrite, strong) NSMutableArray <NSString *>*fnames;
@property (nonatomic, readwrite, strong) NSMutableArray <NSString *>*addresses;
@property (nonatomic, readwrite, strong) NSMutableArray <NSString *>*symbols;
@property (nonatomic, readwrite, strong) NSMutableArray <NSNumber *>*offsets;
@property (nonatomic, readwrite, assign) thread_t thread;
@property (nonatomic, readwrite, copy) NSString *symbolsDescription;
@property (nonatomic, readwrite, copy) NSString *queueName;
@end

@implementation SNKBackTrace

+ (instancetype)backTraceWith:(thread_t)thread {
    SNKBackTrace *instance = [SNKBackTrace new];
    instance.fnames = [NSMutableArray arrayWithCapacity:MAX_CALL_STACK_SIZE];
    instance.addresses = [NSMutableArray arrayWithCapacity:MAX_CALL_STACK_SIZE];
    instance.symbols = [NSMutableArray arrayWithCapacity:MAX_CALL_STACK_SIZE];
    instance.offsets = [NSMutableArray arrayWithCapacity:MAX_CALL_STACK_SIZE];
    instance.thread = thread;
    instance.symbolsDescription = [instance callStackSymbolsDescription];
    return instance;
}

- (NSString *)queueName {
    if (!_queueName) {
        struct thread_identifier_info idInfo;
        generate_identifier_info(_thread, &idInfo);
        char buffer[256];
        if (mach_thread_get_queue_name(idInfo, buffer, 256)) {
            NSString *queueName = [[NSString alloc] initWithCString:buffer encoding:NSUTF8StringEncoding];
            _queueName = queueName;
        } else {
            _queueName = @"Null";
        }
    }
    return _queueName;
}

- (NSString *)callStackSymbolsDescription {
    _STRUCT_MCONTEXT machineContext;
    if (!getMachineContext(_thread, &machineContext)) {
        return [NSString stringWithFormat:@"Error: fail get thread(%u) state", _thread];
    }
    
    uintptr_t pc = j_machInstructionPointerByCPU(&machineContext);
    uintptr_t fp = j_machFramePointerByCPU(&machineContext);
    uintptr_t lr = j_machLinkerPointerByCPU(&machineContext);
    uintptr_t pcArr[MAX_CALL_STACK_SIZE];
    int i = 0;
    pcArr[i++] = pc;
    pj_stack_frame_fp_lr_t frame = {(void *)fp, lr};
    vm_size_t len = sizeof(frame);
    while (frame.fp && i < MAX_CALL_STACK_SIZE) {
        pcArr[i++] = frame.lr;
        bool flag = readFPMemory(frame.fp, &frame, len);
        if (!flag || frame.fp==0 || frame.lr==0) {
            break;
        }
    }
    return [self generateSymbol:pcArr arrLen:i];
}
- (NSString *)generateSymbol:(uintptr_t *)pcArr arrLen:(int)arrLen {
    pj_call_stack_info_t *csInfo = (pj_call_stack_info_t *)malloc(sizeof(pj_call_stack_info_t));
    if (csInfo == NULL) {
        return @"malloc fail";
    }
    csInfo->length = 0;
    csInfo->allocLength = arrLen;
    csInfo->stacks = (pj_func_info_t *)malloc(sizeof(pj_func_info_t) * csInfo->allocLength);
    if (csInfo->stacks == NULL) {
        freeMemory(csInfo);
        return @"malloc fail";
    }
    callStackOfSymbol(pcArr, arrLen, csInfo);
    NSMutableString *strM = [NSMutableString string];
    for (int j = 0; j < csInfo->length; j++) {
        [strM appendFormat:@"%@", [self formatFuncInfo:csInfo->stacks[j]]];
    }
    freeMemory(csInfo);
    return strM.copy;
}

- (NSString *)formatFuncInfo:(pj_func_info_t)info {
    if (info.symbol == NULL) {
        return @"";
    }
    char *lastPath = strrchr(info.machOName, '/');
    NSString *fname = @"";
    if (lastPath == NULL) {
        fname = [NSString stringWithFormat:@"%-30s", info.machOName];
    } else {
        fname = [NSString stringWithFormat:@"%-30s", lastPath+1];
    }
    [_fnames addObject:fname];
    [_offsets addObject:@(info.offset)];
    [_addresses addObject:[NSString stringWithFormat:@"0x%08" PRIxPTR "", (uintptr_t)info.addr]];
    [_symbols addObject:[NSString stringWithFormat:@"%s", info.symbol]];
    return [NSString stringWithFormat:@"%@ 0x%08" PRIxPTR " %s  +  %llu\n", fname, (uintptr_t)info.addr, info.symbol, info.offset];
}
@end
