//
//  Indicator.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/20.
//

import Foundation

// 指标类型
public protocol IndicatorType {
    // 名称
    var name: String { get }
    // 标题
    var title: String { get }
    // 详细描述
    var description: String { get }
    // 调用栈
    var callStacks: [SNKBackTrace] { get }
    // 线程信息
    var infos: [String: Any] { get }
}

// 锁类型
public enum DeadLockType {
    // 互斥锁
    case mutex(_ holding: SNKBackTrace, _ waitings: [SNKBackTrace])
}

// 高CPU占用类型
public enum HighCPUUsageType {
    // 线程占用过高
    case thread(_ providing: MachInfoProvider, usage: Float)
    // 进程总占用过高
    case process(_ prividings: [MachInfoProvider], usage: Float)
}

// 长运行时间
public enum LongRunningType {
    // 系统态耗时过久
    case system(_ providing: MachInfoProvider, millisecond: Float)
    // 用户态耗时过久
    case user(_ providing: MachInfoProvider, millisecond: Float)
    // 总耗时过久
    case total(_ providing: MachInfoProvider, millisecond: Float)
}

// 指标
public enum Indicator: IndicatorType {
    case deadLock(_ type: DeadLockType)
    case priorityInversion(_ t: MachInfoProvider, currentPriority: Int32)
    case longWaiting(_ t: MachInfoProvider, millisecond: Float)
    case longRunning(_ t: LongRunningType)
    case highCPUUsage(_ type: HighCPUUsageType)
    public var name: String {
        switch self {
        case .deadLock:
            return "DEAD_LOCK_DETACHED"
        case .priorityInversion:
            return "PROORITY_INVERSION_DETACHED"
        case .longWaiting:
            return "LONG_WAITING"
        case .longRunning(let t):
            switch t {
            case .system:
                return "LONG_SYSTEM_RUNNING"
            case .user:
                return "LONG_USER_RUNNING"
            case .total:
                return "LONG_RUNNING"
            }
            return "LONG_RUNNING"
        case .highCPUUsage(let t):
            switch t {
            case .thread:
                return "THREAD_CPU_HIGH"
            case .process:
                return "PROCESS_CPU_HIGH"
            }
        }
    }
    public var title: String {
        switch self {
        case let .deadLock(type):
            switch type {
            case .mutex(let h, _):
                guard let s = h.symbols.firstObject as? String else { return "Null" }
                return "\(h.thread)(\(h.thread.name)\(h.queueName)):\(s)"
            }
        case let .priorityInversion(p, cp):
            return "\(p.thread)(\(cp))"
        case let .longWaiting(p, m):
            return "\(p.thread)(\(m)ms)"
        case .longRunning(let t):
            switch t {
            case let .system(p, s):
                guard let extendInfo = p.extendInfo else { return "Couldnt get thread extend info:\(p.thread)" }
                return "\(p.thread)(\(s)ms)"
            case let .user(p, s):
                guard let extendInfo = p.extendInfo else { return "Couldnt get thread extend info:\(p.thread)" }
                return "\(p.thread)(\(s)ms)"
            case let .total(p, s):
                guard let extendInfo = p.extendInfo else { return "Couldnt get thread extend info:\(p.thread)" }
                return "\(p.thread)(\(s)ms)"
            }
        case .highCPUUsage(let t):
            switch t {
            case let .thread(p, u):
                return "\(p.thread)(\(p.thread.name) in \(p.thread.identifierInfo?.queueName ?? ""))(\(u*100)%):"
            case let .process(ps, u):
                return "\(ps.count) threads amounts to \(u*100)%."
            }
        }
    }
    public var description: String {
        switch self {
        case let .deadLock(type):
            switch type {
            case let .mutex(h, ws):
                let wsp = ws.reduce("") { $0 + "\($1.thread)(\($1.threadName) in \($1.queueName))" + "\n" }
                return "HoldingThreadInfo:\(h.thread)(\(h.threadName) in \(h.queueName))\nWaitingThreadInfos:\(wsp)"
            }
        case let .priorityInversion(p, cp):
            guard let extendInfo = p.thread.extendInfo else { return "Couldnt get thread extend info:\(p.thread)" }
            return "Base Priority:\(extendInfo.pth_priority)\nCurrent Priority:\(cp)\nMax Priority:\(extendInfo.pth_maxpriority)\nPolicy:\(extendInfo.policy.desc)"
        case let .longWaiting(p, m):
            guard let extendInfo = p.thread.extendInfo else { return "Couldnt get thread extend info:\(p.thread)" }
            return "State:\(extendInfo.machStateDesc)\nFlag:\(extendInfo.flagDesc)\nSlept Time:\(m)ms"
        case .longRunning(let t):
            switch t {
            case let .system(p, m):
                guard let extendInfo = p.extendInfo else { return "Couldnt get thread extend info:\(p.thread)" }
                return "State:\(extendInfo.machStateDesc)\nFlag:\(extendInfo.flagDesc)\nSystem Time:\(m)ms"
            case let .user(p, m):
                guard let extendInfo = p.extendInfo else { return "Couldnt get thread extend info:\(p.thread)" }
                return "State:\(extendInfo.machStateDesc)\nFlag:\(extendInfo.flagDesc)\nUser Time:\(m)ms"
            case let .total(p, m):
                guard let extendInfo = p.extendInfo else { return "Couldnt get thread extend info:\(p.thread)" }
                return "State:\(extendInfo.machStateDesc)\nFlag:\(extendInfo.flagDesc)\nTotal Time:\(m)ms"
            }
        case .highCPUUsage(let t):
            switch t {
            case let .thread(p, _):
                return ""
            case let .process(ps, _):
                return ps.reduce("ProcessThreadsInfo:\n") { $0 + "\($1.thread)(\($1.thread.name) in \($1.thread.identifierInfo?.queueName ?? "")):\($1.thread.basicInfo?.cpuUsage ?? "")" + "\n" }
            }
        }
    }
    public var callStacks: [SNKBackTrace] {
        switch self {
        case let .deadLock(type):
            switch type {
            case let .mutex(holding, waitings):
                var result = [holding]
                result += waitings
                return result
            }
        case .priorityInversion(let p, _):
            return [SNKBackTrace(p.thread)]
        case let .longWaiting(p, _):
            return [SNKBackTrace(p.thread)]
        case let .longRunning(t):
            switch t {
            case let .system(p, _):
                return [SNKBackTrace(p.thread)]
            case let .user(p, _):
                return [SNKBackTrace(p.thread)]
            case let .total(p, _):
                return [SNKBackTrace(p.thread)]
            }
        case .highCPUUsage(let t):
            switch t {
            case let .thread(p, _):
                return [SNKBackTrace(p.thread)]
            case let .process(ps, _):
                return ps.compactMap { SNKBackTrace($0.thread) }
            }
        }
    }
    
    public var infos: [String : Any] {
        switch self {
        case let .deadLock(type):
            switch type {
            case let .mutex(holding, waitings):
                var r = [String: Any]()
                r["Holding Thread"] = holding.thread.descHashable
                var w = [UInt32: [String: Any]]()
                waitings.forEach {
                    w[$0.thread] = $0.thread.descHashable
                }
                r["Waiting Threads"] = w
                return r
            }
        case .priorityInversion(let p, _):
            return p.thread.descHashable
        case let .longWaiting(p, _):
            return p.thread.descHashable
        case let .longRunning(t):
            switch t {
            case let .system(p, _):
                return p.thread.descHashable
            case let .user(p, _):
                return p.thread.descHashable
            case let .total(p, _):
                return p.thread.descHashable
            }
        case .highCPUUsage(let t):
            switch t {
            case let .thread(p, _):
                return p.thread.descHashable
            case let .process(ps, _):
                var r = [String: Any]()
                ps.forEach { r["\($0.thread)"] = $0.thread.descHashable }
                return r
            }
        }
    }
}
