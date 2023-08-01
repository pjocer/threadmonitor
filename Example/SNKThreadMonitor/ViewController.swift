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

    var count: Int = 0
    
    lazy var thread = {
        let thread = Thread {
            print("my.test.thread is running")
            Thread.sleep(forTimeInterval: 3)
        }
        thread.name = "my.test.thread"
        return thread
    }()
    
    let queue = DispatchQueue(label: "my.test.concurrent.queue", attributes: .concurrent)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ThreadMonitor.shared.registerDelegate(self)
        ThreadMonitor.shared.frequency = 2
        ThreadMonitor.shared.startMonitoring()
        let run = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        run.setTitleColor(.blue, for: .normal)
        run.setTitle("Run", for: .normal)
        run.tag = 1
        run.addTarget(self, action: #selector(runThread(_ :)), for: .touchUpInside)
        view.addSubview(run)
        let cancel = UIButton(frame: CGRect(x: 100, y: 200, width: 100, height: 50))
        cancel.setTitleColor(.blue, for: .normal)
        cancel.setTitle("Cancel", for: .normal)
        cancel.tag = 2
        cancel.addTarget(self, action: #selector(runThread(_ :)), for: .touchUpInside)
        view.addSubview(cancel)
        let exit = UIButton(frame: CGRect(x: 100, y: 300, width: 100, height: 50))
        exit.setTitleColor(.blue, for: .normal)
        exit.setTitle("Exit", for: .normal)
        exit.tag = 3
        exit.addTarget(self, action: #selector(runThread(_ :)), for: .touchUpInside)
        view.addSubview(exit)
        
//        let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
//            for _ in 0..<1 {
//                self.queue.async {
////                    sleep(3)
//                    self.count += 1
//                    print("current count:\(self.count) \(ThreadMonitor.currentInfo().description)")
//                    let queueAddress = withUnsafePointer(to: self.queue) { ptr in
//                        return ptr
//                    }
//                    print("queue addr: \(queueAddress)")
//                }
//            }
//        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 500, execute: DispatchWorkItem(block: {
            ThreadMonitor.shared.stopMonitoring()
//            timer.invalidate()
        }))
    }
    
    @objc func runThread(_ sendor: UIButton) {
        switch sendor.tag {
        case 1:
            self.thread.start()
        case 2:
            self.thread.cancel()
        case 3:
            Thread.exit()
        default:
            print("Nothing")
        }
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
        print("\nThreadMonitorDidReceiveInfosUpdated:👺👺👺👺")
        infos.forEach { info in
            print("\n\(info.description)")
        }
    }
}

class ThreadMonitorStateDelegate: ThreadMonitorIntrospectionStateProviding {
    func threadMonitorDidReceiveStateChanged(_ info: POSIXInfoProvider) {
        print("\nThreadMonitorDidReceiveStateChanged:🎃🎃🎃🎃")
        print("\n\(info.description)")
    }
}

extension ViewController: ThreadMonitorDelegate {
    var threadNotifyDelegate: ThreadMonitorNotifyProviding? { ThreadMonitorNotifyDelegate() }
    var threadInfosDelegate: ThreadMonitorInfosProviding? { ThreadMonitorInfosDelegate() }
    var threadStateDelegate: ThreadMonitorIntrospectionStateProviding? { ThreadMonitorStateDelegate() }
}
