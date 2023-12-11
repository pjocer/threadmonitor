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

#import "Consts.swift"
#import "Error.swift"
#import "MachBasicInfo+Desc.swift"
#import "MachExtendedInfo+Desc.swift"
#import "MachIdentifierInfo+Desc.swift"
#import "MachThread+Utils.swift"
#import "POSIXThread+Utils.swift"
#import "time_value_t+Codable.swift"
#import "Indicator.swift"
#import "ThreadInfo.swift"
#import "ThreadMonitor.swift"

FOUNDATION_EXPORT double SNKThreadMonitorVersionNumber;
FOUNDATION_EXPORT const unsigned char SNKThreadMonitorVersionString[];

