//
//  lock_checker.h
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/22.
//

#import <Foundation/Foundation.h>

void mach_check_thread_dead_lock(thread_t thread,
                                 NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic);

BOOL checkIfIsCircleWithThreadWaitDic(NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic);
void checkThreadIDWith(NSNumber *threadID,
                       NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic,
                       NSMutableDictionary<NSNumber *,NSNumber *> *visited,
                       NSMutableArray *path,
                       BOOL *hasCircle);
void checkMainEmptyCPUUsageWithWapped(thread_t thread,
                                      uint64_t thread_id,
                                      NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic);
// TODO: 待补充
void checkMainHighCPUUsage(thread_t thread,
                           uint64_t thread_id ,
                           NSMutableDictionary<NSNumber *,NSMutableArray<NSNumber *> *> *threadWaitDic);
