//
//  MachExtendedInfo+Desc.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/12/8.
//

import Foundation

public extension MachExtendedInfo {
    // 系统内核标记的线程状态
    public var machState: ThreadMachState? {
        return ThreadMachState(rawValue: Int(pth_run_state))
    }
    public var machStateDesc: String {
        guard let machState = machState else { return "Unknown(\(pth_run_state))" }
        return machState.desc
    }
    // 系统对线程的状态标记
    public var flag: ThreadFlagsType? { ThreadFlagsType(rawValue: Int(pth_flags)) }
    public var flagDesc: String {
        guard let flag = flag else { return "Unknown(\(pth_flags))" }
        return flag.desc
    }
    // CPU占用情况
    public var cpuUsage: String {
        return "\(Float(pth_cpu_usage)*100/Float(TH_USAGE_SCALE))%"
    }
    // 调度策略
    public var policy: ThreadPolicyOptions {
        ThreadPolicyOptions(rawValue: pth_policy)
    }
    
    // 线程名称
    public var name: String {
        let ccharArray = withUnsafeBytes(of: pth_name) { Array($0) }
        if let nullTerminatorIndex = ccharArray.firstIndex(of: 0) {
            let data = Data(ccharArray[..<nullTerminatorIndex])
            if let string = String(data: data, encoding: .utf8) {
                return string.count > 0 ? string : "Null"
            }
        }
        return "Error: No null terminator"
    }
    // 扩展信息描述
    public var desc: [String: Any] {
        var dictionary = [String: Any]()
        let mirror = Mirror(reflecting: self)
        for (key, value) in mirror.children {
            if let key = key {
                if key == "pth_run_state" {
                    dictionary[key] = machStateDesc
                } else if key == "pth_flags" {
                    dictionary[key] = flagDesc
                } else if key == "pth_cpu_usage" {
                    dictionary[key] = cpuUsage
                } else if key == "pth_name" {
                    dictionary[key] = name
                } else if key == "pth_policy" {
                    dictionary[key] = policy.desc
                } else {
                    dictionary[key] = value
                }
            }
        }
        return dictionary
    }
}

extension MachExtendedInfo {
    func notifyRunningWarningsIfNeeded(_ providing: MachInfoProvider) {
        if !providing.thread.isMainThread, flag != nil, machState != .running {
            let systemTime = Float(pth_system_time)/1000/1000
            if systemTime > ThreadMonitor.shared.config.systemRunningThreshold {
                ThreadMonitor.shared.notifyDelegates(.indicator(Indicator.longRunning(.system(providing, millisecond: systemTime))))
            }
            let userTime = Float(pth_user_time)/1000/1000
            if userTime > ThreadMonitor.shared.config.userRunningThreshold {
                ThreadMonitor.shared.notifyDelegates(.indicator(Indicator.longRunning(.user(providing, millisecond: userTime))))
            }
            let totalTime = systemTime + userTime
            if totalTime > ThreadMonitor.shared.config.totalRunningThreshold {
                ThreadMonitor.shared.notifyDelegates(.indicator(Indicator.longRunning(.total(providing, millisecond: totalTime))))
            }
        }
    }
    func notifyWaitingWarningsIfNeeded(_ providing: MachInfoProvider) {
        if machState == .wating, Float(pth_sleep_time)/1000/1000 > ThreadMonitor.shared.config.sleptThreshold {
            ThreadMonitor.shared.notifyDelegates(.indicator(Indicator.longWaiting(providing, millisecond: Float(pth_sleep_time)/1000/1000)))
        }
    }
    func notifyCPUUsageIfNeeded(_ providing: MachInfoProvider, usage: Float) {
        let isMainThread = providing.thread.isMainThread
        let threadThreshold = isMainThread ?  ThreadMonitor.shared.config.mainThreadCPUThreshold : ThreadMonitor.shared.config.threadCPUThreshold
        if usage >= threadThreshold {
            ThreadMonitor.shared.notifyDelegates(.indicator(Indicator.highCPUUsage(.thread(providing, usage: usage))))
        }
    }
}
