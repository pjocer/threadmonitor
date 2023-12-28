//
//  SNKThreadMonitorHandler.swift
//  SnakeGameSingle
//
//  Created by Jocer on 2023/10/20.
//  Copyright © 2023 WepieSnakeGame. All rights reserved.
//
import Foundation
import SNKThreadMonitor

@objcMembers
class SNKThreadMonitorHandler: NSObject {
    
    static let shared = SNKThreadMonitorHandler()
    
    var config: SNKAPMThreadConfig?
    
    func startWith(config: SNKAPMConfig?) {
        guard let config = config, let threadConfig = config.thread, config.threadEnable else { return }
        self.config = threadConfig
        startMonitor()
    }
    
    func startMonitor() {
        guard let config = config else { return }
        
        ThreadMonitor.shared.config = ThreadMonitorConfig(frequency: config.frequency,
                                                          mainThreadCPUThreshold: config.mainThreadCPUThreshold,
                                                          threadCPUThreshold: config.threadCPUThreshold,
                                                          processCPUThreshold: config.processCPUThreshold,
                                                          sleptThreshold: config.sleptThreshold,
                                                          systemRunningThreshold: config.systemRunningThreshold,
                                                          userRunningThreshold: config.userRunningThreshold,
                                                          totalRunningThreshold: config.totalRunningThreshold)
        do {
            ThreadMonitor.shared.registerDelegate(self)
            try ThreadMonitor.shared.startMonitoring()
            beginThreadTransactionCheck("com.snake.wepie.thread-check", interval: 1, max: 30)
        } catch {
            guard let error = error as? ThreadMonitorError else { return }
            print(error.desc)
        }
    }
    
    func pauseMonitor() {
        ThreadMonitor.shared.stopMonitoring()
    }
    
    func resumeMonitor() {
        startMonitor()
    }
    
    @objc
    func beginThreadTransactionCheck(_ identifier: String, interval: TimeInterval, max: Int) {
        ThreadMonitor.shared.beginThreadTransactionCheck(identifier, interval: interval, max: max) { items in
            print(items.reduce("🍭🍭🍭🍭🍭\n", { partialResult, item in
                return partialResult + item.backTrace.symbolsDescription + "\n --------------🧊🧊------------\n"
            }))
        }
    }
    
    @objc
    func beginThreadTransactionCheck(_ identifier: String) {
        ThreadMonitor.shared.beginThreadTransactionCheck(identifier) { items in
            print(items.reduce("🍫🍫🍫🍫🍫\n", { partialResult, item in
                return partialResult + item.backTrace.symbolsDescription + "--------------🧊🧊------------\n"
            }))
        }
    }
    
    @objc
    func endThreadTransactionCheck(_ identifier: String) {
        ThreadMonitor.shared.endThreadTransactionCheck(identifier)
    }
}

extension SNKThreadMonitorHandler: ThreadMonitorIndicatorDetachedProviding {
    func threadMonitorDidReceiveIndicatorDetached(_ indicator: IndicatorType) {
        guard let indicator = indicator as? Indicator else { return }
        SNKThreadMonitorSentryReporter.reportDeadLock(toSentry: indicator.name,
                                                      title: indicator.title,
                                                      desc: indicator.description,
                                                      extra: indicator.infos,
                                                      callStacks: indicator.callStacks)
        return
    }
}

extension SNKThreadMonitorHandler: ThreadMonitorDelegate {
    var indicatorDetachedDelegate: ThreadMonitorIndicatorDetachedProviding? { self }
}
