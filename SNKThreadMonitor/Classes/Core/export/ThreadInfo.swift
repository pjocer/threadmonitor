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
    // 调用堆栈信息
    public var backTraceDesc: String {
        return SNKBackTrace(thread).symbolsDescription
    }
    // 是否活跃
    public var isActive: Bool { basicInfo?.machState == .running || basicInfo?.machState == .uninterruptible }
    // 描述信息
    public var description: String {
        return "\n\(thread.desc)\n\nCallStackSymbols:\n\(backTraceDesc)"
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
    // 是否活跃
    public var isActive: Bool { introspectionState == .create || introspectionState == .start }
    // 描述信息
    public var description: String {
        if let machInfo = thread.machInfo {
            return machInfo.description
        } else {
            return "\nState:\(introspectionState?.desc ?? "Unknown")\nPOSIX Address:\(thread)"
        }
    }
    // Convert to Mach-Thread
    public var machInfoProvider: MachInfoProvider? { thread.machInfo }
    
    public init(_ value: POSIXThread, state: ThreadIntrospectionState?) {
        self.thread = value
        self.introspectionState = state
    }
}
