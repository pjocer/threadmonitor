//
//  context_helper.c
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/22.
//

#include "context_helper.h"

uintptr_t j_firstParamRegister(mcontext_t const machineContext) {
#if defined(__arm64__)
    return machineContext->__ss.__x[0];
#elif defined(__arm__)
    return machineContext->__ss.__x[0];
#elif defined(__x86_64__)
    return machineContext->__ss.__rdi;
#endif
}

thread_state_flavor_t j_threadStateByCPU(void) {
#if defined(__arm64__)
    return ARM_THREAD_STATE64;
#elif defined(__arm__)
    return ARM_THREAD_STATE;
#elif defined(__x86_64__)
    return x86_THREAD_STATE64;
#elif defined(__i386__)
    return x86_THREAD_STATE32;
#endif
}
mach_msg_type_number_t j_threadStateCountByCPU(void) {
#if defined(__arm64__)
    return ARM_THREAD_STATE64_COUNT;
#elif defined(__arm__)
    return ARM_THREAD_STATE_COUNT;
#elif defined(__x86_64__)
    return x86_THREAD_STATE64_COUNT;
#elif defined(__i386__)
    return x86_THREAD_STATE32_COUNT;
#endif
}
uintptr_t j_machInstructionPointerByCPU(mcontext_t const machineContext) {
    //Instruction pointer. Holds the program counter, the current instruction address.
#if defined(__arm64__)
    return machineContext->__ss.__pc;
#elif defined(__arm__)
    return machineContext->__ss.__pc;
#elif defined(__x86_64__)
    return machineContext->__ss.__rip;
#elif defined(__i386__)
    return machineContext->__ss.__eip;
#endif
}
uintptr_t j_machFramePointerByCPU(mcontext_t const machineContext) {
    //Instruction pointer. Holds the program counter, the current instruction address.
#if defined(__arm64__)
    return machineContext->__ss.__fp;
#elif defined(__arm__)
    return machineContext->__ss.__r[7];
#elif defined(__x86_64__)
    return machineContext->__ss.__rbp;
#elif defined(__i386__)
    return machineContext->__ss.__ebp;
#endif
}
uintptr_t j_machLinkerPointerByCPU(mcontext_t const machineContext) {
    //Instruction pointer. Holds the program counter, the current instruction address.
#if defined(__arm64__)
    return machineContext->__ss.__lr;
#elif defined(__arm__)
    return machineContext->__ss.__lr;
#elif defined(__x86_64__)
    return machineContext->__ss.__rlr;
#elif defined(__i386__)
    return machineContext->__ss.__elr;
#endif
}
