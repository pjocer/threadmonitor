//
//  lock_indicator.h
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/22.
//

#ifndef lock_indicator_h
#define lock_indicator_h

#import <stdio.h>
#import <os/lock.h>

typedef os_unfair_lock _pthread_lock;

struct pthread_mutex_options_s {
    uint32_t
        protocol:2,
        type:2,
        pshared:2,
        policy:3,
        hold:2,
        misalign:1,
        notify:1,
        mutex:1,
        ulock:1,
        unused:1,
        lock_count:16;
};

typedef struct _pthread_mutex_ulock_s {
    uint32_t uval;
} *_pthread_mutex_ulock_t;

struct pthread_mutex_s {
    long sig;
    _pthread_lock lock;
    union {
        uint32_t value;
        struct pthread_mutex_options_s options;
    } mtxopts;
    int16_t prioceiling;
    int16_t priority;
#if defined(__LP64__)
    uint32_t _pad;
#endif
    union {
        struct {
            uint32_t m_tid[2]; // thread id of thread that has mutex locked
            uint32_t m_seq[2]; // mutex sequence id
            uint32_t m_mis[2]; // for misaligned locks m_tid/m_seq will span into here
        } psynch;
        struct _pthread_mutex_ulock_s ulock;
    };
#if defined(__LP64__)
    uint32_t _reserved[4];
#else
    uint32_t _reserved[1];
#endif
};

#endif /* lock_indicator_h */
