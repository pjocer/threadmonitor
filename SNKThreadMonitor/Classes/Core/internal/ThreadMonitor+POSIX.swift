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
            // TODO: 通过addr偏移寻址，拿到对应的程序计数器信息
            self?.updatePOSIXInfo(with: state, pthread: pthread) { info in
                guard let state = info.introspectionState else { return }
                switch state {
                case .create:
                    self?.notifyDelegates(.state(.create(info)))
                    break
                case .start:
                    self?.notifyDelegates(.state(.start(info)))
                    break
                case .terminate:
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
