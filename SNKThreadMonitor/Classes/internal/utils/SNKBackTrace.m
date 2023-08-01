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

@interface SNKBackTrace()
@property (nonatomic, readwrite, copy) NSArray <NSString *>*symbols;
@property (nonatomic, readwrite, copy) NSArray <NSString *>*addresses;
@property (nonatomic, readwrite, copy) NSString *symbolsDescription;
@end

@implementation SNKBackTrace

+ (instancetype)backTraceWith:(thread_t)thread {
    SNKBackTrace *bt = [SNKBackTrace new];
    void *callStackAddresses[MAX_CALL_STACK_SIZE];
    size_t callStackSize = 0;
    getThreadStackInfo(thread, callStackAddresses, &callStackSize);
    NSMutableArray<NSString *> *symbolsArray = [NSMutableArray array];
    NSMutableArray<NSString *> *addressesArray = [NSMutableArray array];
    for (size_t i = 0; i < callStackSize; i++) {
        void *addr = callStackAddresses[i];
        if (addr != NULL) {
            Dl_info info;
            if (dladdr(addr, &info) != 0) {
                NSString *symbol = [NSString stringWithUTF8String:info.dli_sname];
                [symbolsArray addObject:symbol];
            }
            NSString *address = [NSString stringWithFormat:@"%p", addr];
            [addressesArray addObject:address];
        }
    }
    bt.symbols = [symbolsArray copy];
    bt.addresses = [addressesArray copy];
    NSMutableString *description = [NSMutableString stringWithString:@"Call symbols and addresses:"];
    [bt.symbols enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [description appendFormat:@"\n%@:%@", bt.addresses[idx], obj];
    }];
    bt.symbolsDescription = description;
    return bt;
}

+ (NSString *)callStackSymbolsDescription:(thread_t)thread {
    _STRUCT_MCONTEXT machineContext;
    if (!getMachineContext(thread, &machineContext)) {
        return [NSString stringWithFormat:@"Error: fail get thread(%u) state", thread];
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
    return generateSymbol(pcArr, i, thread);
}
NSString *generateSymbol(uintptr_t *pcArr, int arrLen, thread_t thread) {
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
    NSMutableString *strM = [NSMutableString stringWithFormat:@"CallStack of thread: %u\n", thread];
    for (int j = 0; j < csInfo->length; j++) {
        [strM appendFormat:@"%@", formatFuncInfo(csInfo->stacks[j])];
    }
    freeMemory(csInfo);
    return strM.copy;
}

NSString *formatFuncInfo(pj_func_info_t info) {
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
    return [NSString stringWithFormat:@"%@ 0x%08" PRIxPTR " %s  +  %llu\n", fname, (uintptr_t)info.addr, info.symbol, info.offset];
}
@end
