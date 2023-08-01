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
    
    // 监控频率（不建议配置太高的频率，使用过高的频率会导致过高的CPU和资源占用）
    public var frequency: TimeInterval = 3
    
    // 活跃线程
    @Protected
    internal var _activeThreadInfo: [MachInfoProvider] = [MachInfoProvider]()
    public var activeThreadInfo: [MachInfoProvider] {
        $_activeThreadInfo.wrappedValue
    }
    
    // 开始监控
    public func startMonitoring() {
        startThreadMonitorring()
        startMonitorringTimer()
        registerThreadStateNotify()
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
    internal lazy var timer: DispatchSourceTimer = {
        DispatchSource.makeTimerSource(queue: monitorQueue)
    }()
    
    internal var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    private init() {}
}
