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

// 指标
public enum Indicator: IndicatorType {
    case deadLock(_ type: DeadLockType)
    case priorityInversion
    case longWaiting
    case longRunning
    case highCPUUsage(_ type: HighCPUUsageType)
    public var name: String {
        switch self {
        case .deadLock:
            return "DEAD_LOCK_DETACHED"
        case .priorityInversion:
            return "PROORITY_INVERSION_DETACHED"
        case .longWaiting:
            return "LONG_WAITING"
        case .longRunning:
            return "LONG_RUNNING"
        case .highCPUUsage(let t):
            switch t {
            case let .thread(p, u):
                return "THREAD_CPU_HIGH(\(u*100)%)"
            case let .process(_, u):
                return "PROCESS_CPU_HIGH(\(u*100)%)"
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
        case .priorityInversion:
            return "优先级反转"
        case .longWaiting:
            return "长时间等待"
        case .longRunning:
            return "执行耗时过久"
        case .highCPUUsage(let t):
            switch t {
            case let .thread(p, _):
                return "\(p.thread)(\(p.thread.name) in \(p.thread.identifierInfo?.queueName ?? "")):"
            case let .process(ps, _):
                return "threads(\(ps.count))"
            }
        }
    }
    public var description: String {
        switch self {
        case let .deadLock(type):
            switch type {
            case let .mutex(h, ws):
                let hp = MachInfoProvider(h.thread)
                let wsp = ws.map{ MachInfoProvider($0.thread) }.reduce("") { $0 + $1.description + "\n" }
                return "HoldingThreadInfo:\(hp.description)\nWaitingThreadInfos:\(wsp)"
            }
        case .priorityInversion:
            return ""
        case .longWaiting:
            return ""
        case .longRunning:
            return ""
        case .highCPUUsage(let t):
            switch t {
            case let .thread(p, _):
                return "ThreadInfo:\n\(p.description)"
            case let .process(ps, _):
                return ps.reduce("ProcessThreadsInfo:\n") { $0 + $1.description + "\n" }
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
        case .priorityInversion:
            return []
        case .longWaiting:
            return []
        case .longRunning:
            return []
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
        case .priorityInversion:
            return [String: Any]()
        case .longWaiting:
            return [String: Any]()
        case .longRunning:
            return [String: Any]()
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
