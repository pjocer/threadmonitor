//
//  ThreadMonitor+TH.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/17.
//

extension ThreadMonitor {
    // 注册NSThread状态通知
    func registerThreadStateNotify() {
        NotificationCenter.default.addObserver(self, selector: #selector(threadWillExit(_:)), name: .NSThreadWillExit, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(threadWillBecomeMulti(_:)), name: .NSWillBecomeMultiThreaded, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(threadDidBecomeSingle(_:)), name: .NSDidBecomeSingleThreaded, object: nil);
        
    }
    
    func unregisterThreadStateNotify() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func searchFromSavedInfos(_ thread: Thread) -> MachInfoProvider? {
        let info = $_activeThreadInfo.read { $0.first { $0.name == thread.name } }
        return info
    }
    
    @objc
    private func threadWillExit(_ note: Notification) {
        let info = searchFromSavedInfos(note.object as! Thread)
        notifyDelegates(.notify(.willExit(note.object as? Thread, info)))
    }
    
    @objc
    private func threadWillBecomeMulti(_ note: Notification) {
        notifyDelegates(.notify(.willBecomeMulti))
    }
    
    @objc
    private func threadDidBecomeSingle(_ note: Notification) {
        notifyDelegates(.notify(.didBecomeSingle))
    }
}

extension ThreadMonitor {
    // 代理回调
    func notifyDelegates(_ `func`: ThreadMonitorDelegateFunction) {
        delegates.allObjects.compactMap { $0 as? ThreadMonitorDelegate }.forEach {
            switch `func` {
            case .infos(let type):
                switch type {
                case .updateAll(let infos):
                    $0.threadInfosDelegate?.threadMonitorDidReceiveInfosUpdated(infos)
                }
            case .notify(let type):
                switch type {
                case let .willExit(thread, info):
                    $0.threadNotifyDelegate?.threadMonitorDidReceiveWillExit(thread: thread, info: info)
                case .willBecomeMulti:
                    $0.threadNotifyDelegate?.threadMonitorDidReceiveWillBecomeMulti()
                case .didBecomeSingle:
                    $0.threadNotifyDelegate?.threadMonitorDidReceiveDidBecomeSingle()
                }
            case .state(let type):
                switch type {
                case let .changed(info):
                    $0.threadStateDelegate?.threadMonitorDidReceiveStateChanged(info)
                case .create(let info):
                    $0.threadStateDelegate?.threadMonitorDidReceiveThreadCreated(info)
                case .start(let info):
                    $0.threadStateDelegate?.threadMonitorDidReceiveThreadStarted(info)
                case .finish(let info):
                    $0.threadStateDelegate?.threadMonitorDidReceiveThreadFinished(info)
                case .destory(let info):
                    $0.threadStateDelegate?.threadMonitorDidReceiveThreadDestroied(info)
                }
            }
        }
    }
}
