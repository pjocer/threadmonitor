//
//  context_helper.h
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/22.
//

#ifndef context_helper_h
#define context_helper_h

#import <stdio.h>
#import <mach/mach.h>

uintptr_t j_firstParamRegister(mcontext_t const machineContext);
thread_state_flavor_t j_threadStateByCPU(void);
mach_msg_type_number_t j_threadStateCountByCPU(void);
uintptr_t j_machInstructionPointerByCPU(mcontext_t const machineContext);
uintptr_t j_machFramePointerByCPU(mcontext_t const machineContext);
uintptr_t j_machLinkerPointerByCPU(mcontext_t const machineContext);

#endif /* context_helper_h */
