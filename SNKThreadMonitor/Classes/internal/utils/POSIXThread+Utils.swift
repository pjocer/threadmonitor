//
//  POSIXThread+Utils.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/20.
//

extension POSIXThread {
    
    static var current: POSIXThread { pthread_self() }
    
    func machInfo() -> MachInfoProvider {
        let mp = pthread_mach_thread_np(self)
        return MachInfoProvider(mp)
    }
    var name: String {
        var buffer = [CChar](repeating: 0, count: 64)
        if getPOSIXThreadName(self, &buffer, buffer.count) {
            return String(cString: buffer)
        }
        return "Error: get posix thread name"
    }
}
