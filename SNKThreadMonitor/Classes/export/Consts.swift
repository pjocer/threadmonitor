//
//  Consts.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/1.
//
import Foundation

// Mach
public typealias MachThread = thread_act_t
public typealias MachBasicInfo = thread_basic_info
public typealias MachIdentifierInfo = thread_identifier_info
public typealias MachExtendedInfo = thread_extended_info
public typealias MachIoStatInfo = io_stat_info

// POSIX
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
    func threadMonitorDidReceiveInfosDeadLockDetached(_ infos: [MachInfoProvider], deadLockInfos: [MachInfoProvider: [MachInfoProvider]])
}

public extension ThreadMonitorInfosProviding {
    func threadMonitorDidReceiveInfosUpdated(_ infos: [MachInfoProvider]) {}
    func threadMonitorDidReceiveInfosDeadLockDetached(_ infos: [MachInfoProvider], deadLockInfos: [MachInfoProvider: [MachInfoProvider]]) {}
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
}

public extension ThreadMonitorDelegate {
    var threadNotifyDelegate: ThreadMonitorNotifyProviding? { nil }
    var threadInfosDelegate: ThreadMonitorInfosProviding? { nil }
    var threadStateDelegate: ThreadMonitorIntrospectionStateProviding? { nil }
}

// 通知
public extension ThreadMonitor {
    // 同`ThreadMonitorInfosProviding.threadMonitorDidReceiveInfosUpdated`
    static let SNKThreadInfoDidUpdatedNotification = Notification.Name("SNKThreadInfoDidUpdatedNotification")
    // 同`ThreadMonitorIntrospectionStateProviding.threadMonitorDidReceiveStateChanged`
    static let SNKInstrspectionStateDidChangedNotification = Notification.Name("SNKThreadInfoInstrspectionStateDidChangedNotification")
}
