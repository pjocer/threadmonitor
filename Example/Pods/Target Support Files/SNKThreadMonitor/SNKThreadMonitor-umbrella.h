#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SNKBackTrace.h"
#import "back_trace.h"
#import "context_helper.h"
#import "lock_checker.h"
#import "lock_indicator.h"
#import "mach.h"
#import "posix.h"

FOUNDATION_EXPORT double SNKThreadMonitorVersionNumber;
FOUNDATION_EXPORT const unsigned char SNKThreadMonitorVersionString[];

