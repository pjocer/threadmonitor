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
}

// 锁类型
public enum DeadLockType {
    // 互斥锁
    case mutex(_ holding: SNKBackTrace, _ waitings: [SNKBackTrace])
}

// 指标
public enum Indicator: IndicatorType {
    case deadLock(_ type: DeadLockType)
    case priorityInversion
    case longWaiting
    case longRunning
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
        }
    }
    public var title: String {
        switch self {
        case let .deadLock(type):
            switch type {
            case .mutex(let h, _):
                let t = SNKBackTrace(h.thread)
                guard let s = t.symbols.firstObject as? String else { return "Null" }
                return "\(t.thread)(\(t.thread.name)\(t.queueName)):\(s)"
            }
        case .priorityInversion:
            return "优先级反转"
        case .longWaiting:
            return "长时间等待"
        case .longRunning:
            return "执行耗时过久"
        }
    }
    public var description: String {
        switch self {
        case let .deadLock(type):
            switch type {
            case let .mutex(h, ws):
                let hp = MachInfoProvider(h.thread)
                let wsp = ws.map{ MachInfoProvider($0.thread) }.reduce("") { $0 + $1.description + "\n" }
                return "HoldingThreadInfo:\n\(hp.description)\nWaitingThreadInfos:\n\(wsp)"
            }
        case .priorityInversion:
            return ""
        case .longWaiting:
            return ""
        case .longRunning:
            return ""
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
        }
    }
}
