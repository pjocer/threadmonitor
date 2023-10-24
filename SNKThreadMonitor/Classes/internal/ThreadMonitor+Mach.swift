//
//  ThreadMonitor+Darwin.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/17.
//
import Darwin

extension ThreadMonitor {
    // 当前线程的信息
    var currentMachInfo: MachInfoProvider { .init(.current) }
    // 启动全局监控的定时器（频率：frequency）
    func startMonitorringTimer() {
        timer.schedule(deadline: .now(), repeating: .seconds(Int(frequency)), leeway: .milliseconds(100))
        timer.setEventHandler(qos: .default, flags: .barrier) {
            self.updateAllThreadInfoTask()
        }
        timer.resume()
    }
    
    func stopMonitorringTimer() {
        timer.cancel()
    }
    
    // 更新线程信息
    func updateAllThreadInfoTask() {
        var threadList: thread_act_array_t? = nil
        var threadCount: mach_msg_type_number_t = 0
        $_activeThreadInfo.wrappedValue.removeAll()
        // 获取当前应用程序的线程列表
        get_thread_list(&threadList, &threadCount)
        let thisThread = MachThread(thread_self())
        let threadWaitDict = NSMutableDictionary()
        for i in 0 ..< Int(threadCount) {
            let machPointer = threadList![i]
            let info = MachInfoProvider(machPointer)
            $_activeThreadInfo.append(info)
            if machPointer != thisThread {
                mach_check_thread_dead_lock(machPointer, threadWaitDict)
            }
        }
        
        if threadWaitDict.count > 0, checkIfIsCircleWithThreadWaitDic(threadWaitDict), let threadWaitDict = threadWaitDict as? [UInt64: [UInt64]] {
            $_activeThreadInfo.read { infos in
                var deadLockInfos = [MachInfoProvider: [MachInfoProvider]]()
                // 存在锁等待
                threadWaitDict.forEach { key, value in
                    if let holdingInfo = infos.first(where: { $0.identifierInfo?.thread_id == key }) {
                        let waitingInfos = value.compactMap { waiting in
                            return infos.first(where: { $0.identifierInfo?.thread_id == waiting })
                        }
                        deadLockInfos[holdingInfo] = waitingInfos
                    }
                }
                self.notifyDelegates(.infos(.deadLockDetached(infos, deadLockInfos: deadLockInfos)))
            }
        }
        $_activeThreadInfo.read {
            NotificationCenter.default.post(name: ThreadMonitor.SNKThreadInfoDidUpdatedNotification, object: $0)
            self.notifyDelegates(.infos(.updateAll($0)))
        }
        // 释放线程列表内存
        deallocate_thread_list(threadList, threadCount)
    }
}
