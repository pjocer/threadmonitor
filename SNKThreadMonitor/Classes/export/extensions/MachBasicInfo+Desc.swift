//
//  MachBasicInfo+Desc.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/12/8.
//

import Foundation

public extension MachBasicInfo {
    // 系统内核标记的线程状态
    public var machState: ThreadMachState? {
        return ThreadMachState(rawValue: Int(run_state))
    }
    public var machStateDesc: String {
        guard let machState = machState else { return "Unknown(\(run_state))" }
        return machState.desc
    }
    // 系统对线程的状态标记
    public var flag: ThreadFlagsType? { ThreadFlagsType(rawValue: Int(flags)) }
    public var flagDesc: String {
        guard let flag = flag else { return "Unknown(\(flags))" }
        return flag.desc
    }
    // CPU占用情况
    public var cpuUsage: String {
        return "\(Float(cpu_usage)*100/Float(TH_USAGE_SCALE))%"
    }
    public var isHigherDetached: Bool {
        return Float(cpu_usage)*100/Float(TH_USAGE_SCALE) >= ThreadMonitor.shared.config.threadCPUThreshold
    }
    // 基础信息描述
    public var desc: [String: Any] {
        var dictionary = [String: Any]()
        let mirror = Mirror(reflecting: self)
        for (key, value) in mirror.children {
            if let key = key {
                if key == "run_state" {
                    dictionary[key] = machStateDesc
                } else if key == "flags" {
                    dictionary[key] = flagDesc
                } else if key == "cpu_usage" {
                    dictionary[key] = cpuUsage
                } else {
                    dictionary[key] = value
                }
            }
        }
        return dictionary
    }
}
