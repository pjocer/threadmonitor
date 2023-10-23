//
//  back_trace.c
//  Pods-SNKThreadMonitor_Example
//
//  Created by Jocer on 2023/8/16.
//

#import "back_trace.h"
#import <execinfo.h>
#import <string.h>
#import <stdlib.h>
#import <libunwind.h>
#import <mach-o/dyld.h>
#import <mach-o/nlist.h>
#import <stdbool.h>
#import <pthread.h>
#import "context_helper.h"

#pragma mark - CallStack

typedef struct {
    const struct mach_header *header;
    const char *name;
    uintptr_t slide;
} pj_mach_header_t;

typedef struct {
    pj_mach_header_t *array;
    uint32_t allocLength;
} pj_mach_header_arr_t;

static pj_mach_header_arr_t *machHeaderArr = NULL;
static pthread_mutex_t initLock = PTHREAD_MUTEX_INITIALIZER;
static bool isInitialized = false;

void getMachHeader(void) {
    machHeaderArr = (pj_mach_header_arr_t *)malloc(sizeof(pj_mach_header_arr_t));
    machHeaderArr->allocLength = _dyld_image_count();
    machHeaderArr->array = (pj_mach_header_t *)malloc(sizeof(pj_mach_header_t) * machHeaderArr->allocLength);
    for (uint32_t i = 0; i < machHeaderArr->allocLength; i++) {
        pj_mach_header_t *machHeader = &machHeaderArr->array[i];
        machHeader->header = _dyld_get_image_header(i);
        machHeader->name = _dyld_get_image_name(i);
        machHeader->slide = _dyld_get_image_vmaddr_slide(i);
    }
    isInitialized = true;
}

void ensureInitialized(void) {
    if (!isInitialized) {
        pthread_mutex_lock(&initLock);
        getMachHeader();
        pthread_mutex_unlock(&initLock);
    }
}

bool pcIsInMach(uintptr_t slidePC, const struct mach_header *header) {
    uintptr_t cur = (uintptr_t)(((struct mach_header_64*)header) + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        struct load_command *command = (struct load_command *)cur;
        if (command->cmd == LC_SEGMENT_64) {
            struct segment_command_64 *segmentCommand = (struct segment_command_64 *)command;
            uintptr_t start = segmentCommand->vmaddr;
            uintptr_t end = segmentCommand->vmaddr + segmentCommand->vmsize;
            if (slidePC >= start && slidePC <= end) {
                return true;
            }
        }
        cur = cur + command->cmdsize;
    }
    return false;
}

pj_mach_header_t *getPCInMach(uintptr_t pc) {
    ensureInitialized();
    for (uint32_t i = 0; i < machHeaderArr->allocLength; i++) {
        pj_mach_header_t *machHeader = &machHeaderArr->array[i];
        if (pcIsInMach(pc-machHeader->slide, machHeader->header)) {
            return machHeader;
        }
    }
    return NULL;
}

void findPCSymbolInMach(uintptr_t pc, pj_mach_header_t *machHeader, pj_call_stack_info_t *csInfo) {
    if (!machHeader) {
        return;
    }
    
    struct segment_command_64 *seg_linkedit = NULL;
    struct symtab_command *sym_command = NULL;
    const struct mach_header *header = machHeader->header;
    uintptr_t cur = (uintptr_t)(((struct mach_header_64*)header) + 1);
    for (uint32_t i = 0; i < header->ncmds; i++) {
        struct load_command *command = (struct load_command *)cur;
        if (command->cmd == LC_SEGMENT_64) {
            struct segment_command_64 *segmentCommand = (struct segment_command_64 *)command;
            if (strcmp(segmentCommand->segname, SEG_LINKEDIT)==0) {
                seg_linkedit = segmentCommand;
            }
        } else if (command->cmd == LC_SYMTAB) {
            sym_command = (struct symtab_command*)command;
        }
        cur = cur + command->cmdsize;
    }
    if (!seg_linkedit || !sym_command) {
        return;
    }
    
    uintptr_t linkedit_base = (uintptr_t)machHeader->slide + seg_linkedit->vmaddr - seg_linkedit->fileoff;
    struct nlist_64 *symtab = (struct nlist_64 *)(linkedit_base + sym_command->symoff);
    const uintptr_t strtab = linkedit_base + sym_command->stroff;
    
    uintptr_t slidePC = pc - machHeader->slide;
    uint64_t offset = UINT64_MAX;
    int best = -1;
    for (uint32_t i = 0; i < sym_command->nsyms; i++) {
        uint64_t distance = slidePC - symtab[i].n_value;
        if (slidePC >= symtab[i].n_value && distance <= offset) {
            offset = distance;
            best = i;
        }
    }
    
    if (best >= 0) {
        pj_func_info_t *funcInfo = &csInfo->stacks[csInfo->length++];
        funcInfo->machOName = machHeader->name;
        funcInfo->addr = symtab[best].n_value;
        funcInfo->offset = offset;
        funcInfo->symbol = (char *)(strtab + symtab[best].n_un.n_strx);
        if (*funcInfo->symbol == '_') {
            funcInfo->symbol++;
        }
        if (funcInfo->machOName == NULL) {
            funcInfo->machOName = "";
        }
    }
}

void callStackOfSymbol(uintptr_t *pcArr, int arrLen, pj_call_stack_info_t *csInfo) {
    for (int i = 0; i < arrLen; i++) {
        pj_mach_header_t *machHeader = getPCInMach(pcArr[i]);
        if (machHeader) {
            findPCSymbolInMach(pcArr[i], machHeader, csInfo);
        }
    }
}

int getMachineContext(thread_t thread, _STRUCT_MCONTEXT64 *machineContext) {
    mach_msg_type_number_t state_count = j_threadStateCountByCPU();
    kern_return_t kr = thread_get_state(thread, j_threadStateByCPU(), (thread_state_t)&machineContext->__ss, &state_count);
    if (kr != KERN_SUCCESS) {
        fprintf(stderr, "Error getMachineContext: %s\n", mach_error_string(kr));
    }
    return KERN_SUCCESS == kr ? 1 : 0;
}

// 读取fp开始，len(16)字节长度的内存。因为stp fp, lr... ， fp占8字节，然后紧接着上面8字节是lr
int readFPMemory(const void *fp, const void *dst, const vm_size_t len) {
    vm_size_t bytesCopied = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)fp, len, (vm_address_t)dst, &bytesCopied);
    if (kr != KERN_SUCCESS) {
        fprintf(stderr, "Error readFPMemory: %s\n", mach_error_string(kr));
    }
    return KERN_SUCCESS == kr ? 1 : 0;
}

void freeMemory(pj_call_stack_info_t *csInfo) {
    if (csInfo->stacks) {
        free(csInfo->stacks);
    }
    if (csInfo) {
        free(csInfo);
    }
}
