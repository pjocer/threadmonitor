//
//  ThreadMonitor+PTH.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/8/17.
//


extension ThreadMonitor {
    var currentPOSIXThreadInfo: POSIXInfoProvider { .init(.current, state: nil) }
}

extension ThreadMonitor {
     
    func updatePOSIXInfo(with state: SNKPthreadIntrospectionState, pthread: POSIXThread, completion:((POSIXInfoProvider)->Void)?) {
        monitorQueue.async(qos: .background, flags: .detached) {
            let state = ThreadIntrospectionState(rawValue: Int(state.rawValue))
            let info = POSIXInfoProvider(pthread, state: state)
            self.notifyDelegates(.state(.changed(info)))
            NotificationCenter.default.post(name: ThreadMonitor.SNKInstrspectionStateDidChangedNotification,
                                            object: info,
                                            userInfo: nil)
            completion?(info)
        }
    }
    
    // 安装线程内省回调函数
    func startThreadMonitorring() throws {
        if instrospection_hook.shared().callback != nil {
            throw ThreadMonitorError.startMonitoringTwice
            return
        }
        instrospection_hook.shared().setPthreadIntrospectionHookCallBack { [weak self] state, pthread, addr, size in
            self?.updatePOSIXInfo(with: state, pthread: pthread) { info in
                guard let state = info.introspectionState else { return }
                let mch_port: MachThread = pthread_mach_thread_np(pthread)
                switch state {
                case .create:
                    ThreadMonitor.shared.checkTransactions.forEach { (key: String, value: SNKThrottle) in
                        value.excuteWork(mch_port)
                    }
                    self?.notifyDelegates(.state(.create(info)))
                    break
                case .start:
                    self?.notifyDelegates(.state(.start(info)))
                    break
                case .terminate:
                    if mch_port > 0, let extendInfo = mch_port.extendInfo {
                        let info = MachInfoProvider(mch_port)
                        extendInfo.notifyRunningWarningsIfNeeded(info)
                    }
                    self?.notifyDelegates(.state(.finish(info)))
                    break
                case .destroy:
                    self?.notifyDelegates(.state(.destory(info)))
                    break
                }
            }
        }
    }
    func stopThreadMonitorring() {
        instrospection_hook.shared().uninstall()
    }
}
