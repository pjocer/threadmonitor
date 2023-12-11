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
@property (nonatomic, readwrite, strong) NSMutableArray <NSNumber *>*machHeaders;
@property (nonatomic, readwrite, strong) NSMutableArray <NSNumber *>*lrAddress;
@property (nonatomic, readwrite, assign) thread_t thread;
@property (nonatomic, readwrite, copy) NSString *symbolsDescription;
@property (nonatomic, readwrite, copy) NSString *queueName;
@property (nonatomic, readwrite, copy) NSString *threadName;
@property (nonatomic, readwrite, assign) NSInteger deep;
@end

@implementation SNKBackTrace

+ (instancetype)backTraceWith:(thread_t)thread {
    return [self backTraceWith:thread deep:MAX_CALL_STACK_SIZE];
}

+ (instancetype)backTraceWith:(thread_t)thread deep:(NSInteger)deep {
    SNKBackTrace *instance = [SNKBackTrace new];
    instance.fnames = [NSMutableArray arrayWithCapacity:deep];
    instance.addresses = [NSMutableArray arrayWithCapacity:deep];
    instance.symbols = [NSMutableArray arrayWithCapacity:deep];
    instance.offsets = [NSMutableArray arrayWithCapacity:deep];
    instance.machHeaders = [NSMutableArray arrayWithCapacity:deep];
    instance.lrAddress = [NSMutableArray arrayWithCapacity:deep];
    instance.thread = thread;
    instance.deep = deep;
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

- (NSString *)threadName {
    if (!_threadName) {
        char buffer[256];
        if (mach_thread_get_name(self.thread, buffer, sizeof(buffer))) {
            NSString *threadName = [NSString stringWithUTF8String:buffer];
            _threadName = threadName;
        } else {
            _threadName = @"Null";
        }
    }
    return _threadName;
}

- (NSString *)callStackSymbolsDescription {
    _STRUCT_MCONTEXT machineContext;
    // 拿到线程对应的机器上下文
    if (!getMachineContext(_thread, &machineContext)) {
        return [NSString stringWithFormat:@"Error: fail get thread(%u) state", _thread];
    }
    // 从上下文中取出PC/FP/LR等寄存器
    uintptr_t pc = j_machInstructionPointerByCPU(&machineContext);
    uintptr_t fp = j_machFramePointerByCPU(&machineContext);
    uintptr_t lr = j_machLinkerPointerByCPU(&machineContext);
    uintptr_t pcArr[self.deep];
    int i = 0;
    pcArr[i++] = pc;
    pj_stack_frame_fp_lr_t frame = {(void *)fp, lr};
    vm_size_t len = sizeof(frame);
    // 按照最大调用深度遍历FP寄存器并保存所有的栈帧
    while (frame.fp && i < self.deep) {
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
    // 构造调用栈信息结构体
    csInfo->length = 0;
    csInfo->allocLength = arrLen;
    csInfo->stacks = (pj_func_info_t *)malloc(sizeof(pj_func_info_t) * csInfo->allocLength);
    if (csInfo->stacks == NULL) {
        freeMemory(csInfo);
        return @"malloc fail";
    }
    // 从每个栈帧所处的镜像地址中逐帧读取对应的调用栈信息
    callStackOfSymbol(pcArr, arrLen, csInfo);
    NSMutableString *strM = [NSMutableString string];
    for (int j = 0; j < csInfo->length; j++) {
        // 格式化堆栈信息
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
    [_machHeaders addObject:[NSNumber numberWithUnsignedLongLong:info.machImageHeader]];
    [_lrAddress addObject:[NSNumber numberWithUnsignedLongLong:info.lr_addr]];
    return [NSString stringWithFormat:@"%@ 0x%08" PRIxPTR " %s  +  %llu\n", fname, (uintptr_t)info.addr, info.symbol, info.offset];
}
@end
