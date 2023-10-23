//
//  ViewController.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 08/01/2023.
//  Copyright (c) 2023 Jocer. All rights reserved.
//

import UIKit
import SNKThreadMonitor
import SwiftyJSON

class ViewController: UIViewController {
    
    var testDeadLockVC = TestDeadLockVC()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ThreadMonitor.shared.registerDelegate(self)
        ThreadMonitor.shared.frequency = 2
        ThreadMonitor.shared.startMonitoring()
        addChild(testDeadLockVC)
        view.addSubview(testDeadLockVC.view)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class ThreadMonitorNotifyDelegate: ThreadMonitorNotifyProviding {
    func threadMonitorDidReceiveWillExit(thread: Thread?, info: (any ThreadInfoProviding)?) {
        
    }
    func threadMonitorDidReceiveWillBecomeMulti() {
        
    }
    func threadMonitorDidReceiveDidBecomeSingle() {
        
    }
}

class ThreadMonitorInfosDelegate: ThreadMonitorInfosProviding {
    func threadMonitorDidReceiveInfosUpdated(_ infos: [MachInfoProvider]) {
//        print("\nThreadMonitorDidReceiveInfosUpdated:👺👺👺👺")
//        infos.forEach { info in
//            print("\n\(info.description)")
//        }
    }
    func threadMonitorDidReceiveInfosDeadLockDetached(_ infos: [MachInfoProvider], deadLockInfos: [MachInfoProvider : [MachInfoProvider]]) {
        print("\nthreadMonitorDidReceiveInfosDeadLockDetached:💩💩💩💩")
        deadLockInfos.forEach { holding, waitings in
            var waitingsDesc = ""
            waitingsDesc = waitings.reduce(into: waitingsDesc) { partialResult, provider in
                partialResult = partialResult + "\n\(provider.description)"
            }
            print("\nHolding Info:\n\(holding.description)\nWaiting Infos:\n\(waitingsDesc)")
        }
    }
}

class ThreadMonitorStateDelegate: ThreadMonitorIntrospectionStateProviding {
    func threadMonitorDidReceiveStateChanged(_ info: POSIXInfoProvider) {
//        print("\nThreadMonitorDidReceiveStateChanged:🎃🎃🎃🎃")
//        print("\n\(info.description)")
    }
}

extension ViewController: ThreadMonitorDelegate {
    var threadNotifyDelegate: ThreadMonitorNotifyProviding? { ThreadMonitorNotifyDelegate() }
    var threadInfosDelegate: ThreadMonitorInfosProviding? { ThreadMonitorInfosDelegate() }
    var threadStateDelegate: ThreadMonitorIntrospectionStateProviding? { ThreadMonitorStateDelegate() }
}
