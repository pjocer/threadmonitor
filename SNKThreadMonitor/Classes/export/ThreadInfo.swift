//
//  ThreadInfo.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/21.
//

public protocol ThreadInfoProviding {
    associatedtype T
    // 线程句柄/端口
    var thread: T { get set }
    // 是否活跃
    var isActive: Bool { get }
    // 描述
    var description: String { get }
}

public struct MachInfoProvider: ThreadInfoProviding, Hashable {
    public typealias T = MachThread
    // 由操作系统内核维护管理的线程端口号
    public var thread: MachThread
    // 线程基础信息
    public var basicInfo: MachBasicInfo? { thread.basicInfo }
    // 线程身份信息
    public var identifierInfo: MachIdentifierInfo? { thread.identifierInfo }
    // 线程扩展信息
    public var extendInfo: MachExtendedInfo? { thread.extendInfo }
    // 系统内核标记的线程状态
    public var machState: ThreadMachState? {
        return ThreadMachState(rawValue: Int(basicInfo?.run_state ?? 0))
    }
    public var machStateDesc: String {
        guard let machState = machState else { return "Unknown(\(basicInfo?.run_state ?? 0))" }
        return machState.desc
    }
    // 系统对线程的状态标记
    public var flag: ThreadFlagsType? { ThreadFlagsType(rawValue: Int(basicInfo?.flags ?? 0)) }
    public var flagDesc: String {
        guard let flag = flag else { return "Unknown(\(basicInfo?.flags ?? 0))" }
        return flag.desc
    }
    // CPU占用情况
    public var cpuUsage: String {
        return "\(Float(basicInfo?.cpu_usage ?? 0)*100/Float(TH_USAGE_SCALE))%"
    }
    // 线程名称
    public var name: String { extendInfo?.name ?? "Null" }
    
    // 调用堆栈信息
    public var backTraceDesc: String {
        return SNKBackTrace(thread).symbolsDescription
    }
    
    public var isActive: Bool { machState == .running || machState == .uninterruptible }
    
    public var description: String {
        let basicInfo = basicInfo
        let identifierInfo = identifierInfo
        let extendInfo = extendInfo
        let string = "\nMach-State:\(machStateDesc)\nQueue Address:\(identifierInfo?.dispatch_qaddr ?? 0)\nThread ID:\(identifierInfo?.thread_id ?? 0)\nThread Mach-Port:\(thread)\nFlag:\(flagDesc)\nSuspend Count:\(basicInfo?.suspend_count ?? 0)\nSleep Time:\(basicInfo?.sleep_time ?? 0)\nName:\(extendInfo?.name ?? "Null")\nQueue Name:\(identifierInfo?.queueName ?? "Null")\nCPU Usage:\(Float(basicInfo?.cpu_usage ?? 0)*100/Float(TH_USAGE_SCALE))%\n\(backTraceDesc)"
        return string
    }
    public init(_ value: MachThread) {
        self.thread = value
    }
}



public struct POSIXInfoProvider: ThreadInfoProviding {
    public typealias T = POSIXThread
    // POSIX框架下的线程句柄
    public var thread: POSIXThread
    // 线程内省状态
    public let introspectionState: ThreadIntrospectionState?
    
    public var isActive: Bool { introspectionState == .create || introspectionState == .start }
    
    public var description: String {
        let string = "\nState:\(introspectionState?.desc ?? "Unknown")\nPOSIX Address:\(thread)"
        return string
    }
    public init(_ value: POSIXThread, state: ThreadIntrospectionState?) {
        self.thread = value
        self.introspectionState = state
    }
    
    public var machInfoProvider: MachInfoProvider? {
        let machThread = pthread_mach_thread_np(thread)
        if machThread > 0 {
            return MachInfoProvider(machThread)
        }
        return nil
    }
}
