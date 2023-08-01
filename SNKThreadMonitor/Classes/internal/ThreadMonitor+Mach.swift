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
        var threadDescDict = NSMutableDictionary()
        var threadWaitDict = NSMutableDictionary()
        for i in 0 ..< Int(threadCount) {
            let machPointer = threadList![i]
            let info = MachInfoProvider(machPointer)
//            mach_check_thread_dead_lock(machPointer, machPointer.identifierInfo, machPointer.extendInfo)
            $_activeThreadInfo.append(info)
            if machPointer != thisThread {
                mach_check_thread_dead_lock(machPointer, threadDescDict, threadWaitDict)
            }
        }
        if threadWaitDict.count > 0 {
            //需要判断死锁
            checkIfIsCircleWithThreadDescDic(threadDescDict, threadWaitDict)
        }
        // 释放线程列表内存
        deallocate_thread_list(threadList, threadCount)
        $_activeThreadInfo.read {
            NotificationCenter.default.post(name: ThreadMonitor.SNKThreadInfoDidUpdatedNotification, object: $0)
            self.notifyDelegates(.infos(.updateAll($0)))
        }
    }
}
