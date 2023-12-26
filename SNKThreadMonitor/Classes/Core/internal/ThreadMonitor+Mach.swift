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
    func startMonitorringTimer() throws {
        if let timer = timer { throw ThreadMonitorError.startMonitoringTwice }
        timer = DispatchSource.makeTimerSource(queue: monitorQueue)
        timer?.schedule(deadline: .now(), repeating: .seconds(Int(config.frequency)), leeway: .milliseconds(100))
        timer?.setEventHandler(qos: .default, flags: .barrier) {
            self.updateAllThreadInfoTask()
        }
        timer?.resume()
    }
    
    func stopMonitorringTimer() {
        timer?.cancel()
        timer = nil
    }
    
    // 更新线程信息
    func updateAllThreadInfoTask() {
        var threadList: thread_act_array_t? = nil
        var threadCount: mach_msg_type_number_t = 0
        $_activeThreadInfo.wrappedValue.removeAll()
        // 获取当前应用程序的线程列表
        get_thread_list(&threadList, &threadCount)
        let threadWaitDict = NSMutableDictionary()
        var totalCPUUsage: Float = 0
        for i in 0 ..< Int(threadCount) {
            let machPointer = threadList![i]
            let info = MachInfoProvider(machPointer)
            $_activeThreadInfo.append(info)
            if let extendInfo = machPointer.extendInfo {
                let usagePercent = Float(extendInfo.pth_cpu_usage) / Float(TH_USAGE_SCALE)
                totalCPUUsage += usagePercent
                extendInfo.notifyCPUUsageIfNeeded(info, usage: usagePercent)
                extendInfo.notifyWaitingWarningsIfNeeded(info)
            }
            mach_check_thread_dead_lock(machPointer, threadWaitDict)
        }
        if totalCPUUsage >= config.processCPUThreshold {
            let sorted = $_activeThreadInfo.wrappedValue.sorted { left, right in
                (left.thread.basicInfo?.cpu_usage ?? 0) > (right.thread.basicInfo?.cpu_usage ?? 0)
            }
            self.notifyDelegates(.indicator(Indicator.highCPUUsage(.process(sorted, usage: totalCPUUsage))))
        }
        checkIfDeadLock(threadWaitDict)
        $_activeThreadInfo.read {
            NotificationCenter.default.post(name: ThreadMonitor.SNKThreadInfoDidUpdatedNotification, object: $0)
            self.notifyDelegates(.infos(.updateAll($0)))
        }
        // 释放线程列表内存
        deallocate_thread_list(threadList, threadCount)
    }
}

extension ThreadMonitor {
    func checkIfDeadLock(_ waitingInfo: NSMutableDictionary) {
        if waitingInfo.count > 0, checkIfIsCircleWithThreadWaitDic(waitingInfo), let waitingInfo = waitingInfo as? [UInt64: [UInt64]] {
            $_activeThreadInfo.read { infos in
                // 存在锁等待
                waitingInfo.forEach { key, value in
                    if let holdingInfo = infos.first(where: { $0.identifierInfo?.thread_id == key }) {
                        let waitingInfos = value.compactMap { waiting in
                            return infos.first(where: { $0.identifierInfo?.thread_id == waiting })
                        }
                        self.notifyDelegates(.indicator(Indicator.deadLock(.mutex(SNKBackTrace(holdingInfo.thread), waitingInfos.compactMap{ SNKBackTrace($0.thread) }))))
                    }
                }
            }
        }
    }
}
