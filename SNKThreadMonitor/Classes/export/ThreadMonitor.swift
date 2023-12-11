//
//  ThreadMonitor.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/1.
//

import Foundation

public final class ThreadMonitor {
    // 单例
    public static let shared = ThreadMonitor()
    
    // 监控配置
    public var config: ThreadMonitorConfig = ThreadMonitorConfig.default
    
    // 主线程
    internal var _mainThread: MachThread?
    public var mainThread: MachThread? { _mainThread }
    
    // 活跃线程
    @Protected
    internal var _activeThreadInfo: [MachInfoProvider] = [MachInfoProvider]()
    public var activeThreadInfo: [MachInfoProvider] {
        $_activeThreadInfo.wrappedValue
    }
    
    // 开始监控
    public func startMonitoring() throws {
        do {
            try startMonoringCheck()
            try startThreadMonitorring()
            try startMonitorringTimer()
            registerThreadStateNotify()
        } catch {
            throw error
        }
    }
    
    // 注册代理
    public func registerDelegate(_ delegate: ThreadMonitorDelegate) {
        delegates.add(delegate)
    }
    
    // 停止监控
    public func stopMonitoring() {
        stopMonitorringTimer()
        stopThreadMonitorring()
        unregisterThreadStateNotify()
    }
    
    // 监控队列
    internal lazy var monitorQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.snake.thread-monitor",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .workItem)
        return queue
    }()
    
    // 定时器，用于定期更新线程信息
    internal var timer: DispatchSourceTimer?
    
    internal var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    private init() {}
}

extension ThreadMonitor {
    func startMonoringCheck() throws {
        do {
            if _mainThread == nil {
                _mainThread = try getMainMachThread()
            }
            // ...
        } catch {
            throw error
        }
    }
    func getMainMachThread() throws -> MachThread {
        let main = pthread_main_np()
        if main != 0 {
            let result = pthread_mach_thread_np(pthread_self())
            if result == 0 {
                throw ThreadMonitorError.getMachThreadBoundToPThreadFailed
            } else {
                return result
            }
        } else {
            throw ThreadMonitorError.notInitialedInMain
        }
    }
}
