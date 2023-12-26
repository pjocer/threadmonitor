//
//  Consts.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/1.
//
import Foundation

// Mach Thread
public typealias MachThread = thread_act_t
public typealias MachBasicInfo = thread_basic_info
public typealias MachIdentifierInfo = thread_identifier_info
public typealias MachExtendedInfo = thread_extended_info
public typealias MachIoStatInfo = io_stat_info

// POSIX Thread
public typealias POSIXThread = pthread_t

/**
 PTHREAD_INTROSPECTION_THREAD
 POSIX线程内省状态
 */
@frozen
public enum ThreadIntrospectionState: Int {
    case create = 1
    case start
    case terminate
    case destroy
    var desc: String {
        switch self {
        case .destroy:
            return "Destroy"
        case .terminate:
            return "Terminate"
        case .start:
            return "Start"
        case .create:
            return "Create"
        }
    }
}
/**
 TH_STATE
 系统/CPU内核状态
 */
@frozen
public enum ThreadMachState: Int {
    case running = 1
    case stopped
    case wating
    case uninterruptible
    case halted
    var desc: String {
        switch self {
        case .running:
            return "Running"
        case .stopped:
            return "Stopped"
        case .wating:
            return "Waiting"
        case .uninterruptible:
            return "Uninterruptible"
        case .halted:
            return "Halted"
        }
    }
}
/**
 TH_FLAGS
 系统/CPU开放的标记位
 */
@frozen
public enum ThreadFlagsType: Int {
    case swapped = 0x1
    case idle = 0x2
    case forcedIdle = 0x4
    var desc: String {
        switch self {
        case .swapped:
            return "Swapped out"
        case .idle:
            return "Idle thread"
        case .forcedIdle:
            return "Global forced idle"
        }
    }
}

/**
 MACH_POLICY
 线程调度策略
 */
public struct ThreadPolicyOptions: OptionSet {
    public let rawValue: Int32
    public static let null = ThreadPolicyOptions([])
    public static let timeShare = ThreadPolicyOptions(rawValue: 1 << 0)
    public static let roundRobin = ThreadPolicyOptions(rawValue: 1 << 1)
    public static let fifo = ThreadPolicyOptions(rawValue: 1 << 2)
    public static let fixedPriority: ThreadPolicyOptions = [.roundRobin, .fifo]
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    public var desc: String {
        var descriptions: [String] = []
        if self.contains(.null) {
            descriptions.append("Null")
        }
        if self.contains(.timeShare) {
            descriptions.append("Time Share")
        }
        if self.contains(.fixedPriority) {
            descriptions.append("Fixed Priority")
        } else if self.contains(.roundRobin) {
            descriptions.append("Round Robin")
        } else if self.contains(.fifo) {
            descriptions.append("FIFO")
        }
        if descriptions.isEmpty {
            descriptions.append("Unknown Priority:\(rawValue)")
        }
        return descriptions.joined(separator: ", ")
    }
}

/**
 监控器配置
 */
public struct ThreadMonitorConfig {
    
    static let millisecondPerFrame = Float(1000/60.0)
    
    static let `default` = ThreadMonitorConfig(frequency: 3, 
                                               mainThreadCPUThreshold: 1,
                                               threadCPUThreshold: 0.6,
                                               processCPUThreshold: 2,
                                               sleptThreshold: millisecondPerFrame,
                                               systemRunningThreshold: 20*millisecondPerFrame,
                                               userRunningThreshold: 60*millisecondPerFrame,
                                               totalRunningThreshold: 100*millisecondPerFrame)
    
    // 监控频率（不建议配置太高的频率，使用过高的频率会导致过高的CPU和资源占用）
    public var frequency: TimeInterval
    // 主线程的CPU占用率上报阈值
    public var mainThreadCPUThreshold: Float
    // 单一线程的CPU占用率上报阈值
    public var threadCPUThreshold: Float
    // 当前进程的CPU占用率上报阈值
    public var processCPUThreshold: Float
    // 单一线程的睡眠时间上报阈值(毫秒)
    public var sleptThreshold: Float
    // 单一线程的系统态耗时上报阈值(毫秒)
    public var systemRunningThreshold: Float
    // 单一线程的用户态耗时上报阈值(毫秒)
    public var userRunningThreshold: Float
    // 单一线程的总执行时长上报阈值(毫秒)
    public var totalRunningThreshold: Float
    
    public init(frequency: TimeInterval, mainThreadCPUThreshold: Float, threadCPUThreshold: Float, processCPUThreshold: Float, sleptThreshold: Float, systemRunningThreshold: Float, userRunningThreshold: Float, totalRunningThreshold: Float) {
        self.frequency = frequency
        self.mainThreadCPUThreshold = mainThreadCPUThreshold
        self.threadCPUThreshold = threadCPUThreshold
        self.processCPUThreshold = processCPUThreshold
        self.sleptThreshold = sleptThreshold
        self.systemRunningThreshold = systemRunningThreshold
        self.userRunningThreshold = userRunningThreshold
        self.totalRunningThreshold = totalRunningThreshold
    }
}

// NSThread定义的全局通知回调
public protocol ThreadMonitorNotifyProviding: AnyObject {
    func threadMonitorDidReceiveWillExit(thread: Thread?, info: (any ThreadInfoProviding)?)
    func threadMonitorDidReceiveWillBecomeMulti()
    func threadMonitorDidReceiveDidBecomeSingle()
}
public extension ThreadMonitorNotifyProviding {
    func threadMonitorDidReceiveWillExit(thread: Thread?, info: (any ThreadInfoProviding)?) {}
    func threadMonitorDidReceiveWillBecomeMulti() {}
    func threadMonitorDidReceiveDidBecomeSingle() {}
}

// 定时刷新的全局线程信息回调
// infos: ThreadMonitor.recordedThreadInfo
public protocol ThreadMonitorInfosProviding: AnyObject {
    func threadMonitorDidReceiveInfosUpdated(_ infos: [MachInfoProvider])
}

public extension ThreadMonitorInfosProviding {
    func threadMonitorDidReceiveInfosUpdated(_ infos: [MachInfoProvider]) {}
}

// 触发阈值
public protocol ThreadMonitorIndicatorDetachedProviding: AnyObject {
    func threadMonitorDidReceiveIndicatorDetached(_ indicator: IndicatorType)
    func threadMonitorDidReceiveInfosMutexDeadLockDetached(_ holding: SNKBackTrace, waitings: [SNKBackTrace])
}
public extension ThreadMonitorIndicatorDetachedProviding {
    func threadMonitorDidReceiveIndicatorDetached(_ indicator: IndicatorType) {}
    func threadMonitorDidReceiveInfosMutexDeadLockDetached(_ holding: SNKBackTrace, waitings: [SNKBackTrace]) {}
}

// 线程内省状态回调
public protocol ThreadMonitorIntrospectionStateProviding: AnyObject {
    func threadMonitorDidReceiveStateChanged(_ info: POSIXInfoProvider)
    func threadMonitorDidReceiveThreadCreated(_ info: POSIXInfoProvider)
    func threadMonitorDidReceiveThreadStarted(_ info: POSIXInfoProvider)
    func threadMonitorDidReceiveThreadFinished(_ info: POSIXInfoProvider)
    func threadMonitorDidReceiveThreadDestroied(_ info: POSIXInfoProvider)
}
public extension ThreadMonitorIntrospectionStateProviding {
    func threadMonitorDidReceiveStateChanged(_ info: POSIXInfoProvider) {}
    func threadMonitorDidReceiveThreadCreated(_ info: POSIXInfoProvider) {}
    func threadMonitorDidReceiveThreadStarted(_ info: POSIXInfoProvider) {}
    func threadMonitorDidReceiveThreadFinished(_ info: POSIXInfoProvider) {}
    func threadMonitorDidReceiveThreadDestroied(_ info: POSIXInfoProvider) {}
}

// ThreadMonitorDelegate
public protocol ThreadMonitorDelegate: AnyObject {
    var threadNotifyDelegate: ThreadMonitorNotifyProviding? { get }
    var threadInfosDelegate: ThreadMonitorInfosProviding? { get }
    var threadStateDelegate: ThreadMonitorIntrospectionStateProviding? { get }
    var indicatorDetachedDelegate: ThreadMonitorIndicatorDetachedProviding? { get }
}

public extension ThreadMonitorDelegate {
    var threadNotifyDelegate: ThreadMonitorNotifyProviding? { nil }
    var threadInfosDelegate: ThreadMonitorInfosProviding? { nil }
    var threadStateDelegate: ThreadMonitorIntrospectionStateProviding? { nil }
    var indicatorDetachedDelegate: ThreadMonitorIndicatorDetachedProviding? { nil }
}

// 通知
public extension ThreadMonitor {
    // 同`ThreadMonitorInfosProviding.threadMonitorDidReceiveInfosUpdated`
    static let SNKThreadInfoDidUpdatedNotification = Notification.Name("SNKThreadInfoDidUpdatedNotification")
    // 同`ThreadMonitorIntrospectionStateProviding.threadMonitorDidReceiveStateChanged`
    static let SNKInstrspectionStateDidChangedNotification = Notification.Name("SNKThreadInfoInstrspectionStateDidChangedNotification")
}
