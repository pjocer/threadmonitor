//
//  POSIXThread+Utils.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/20.
//

public extension POSIXThread {
    
    public static var current: POSIXThread { pthread_self() }
    
    public var machInfo: MachInfoProvider? {
        let mp = pthread_mach_thread_np(self)
        if mp > 0 {
            return MachInfoProvider(mp)
        } else {
            return nil
        }
    }
    public var name: String {
        var buffer = [CChar](repeating: 0, count: 64)
        if getPOSIXThreadName(self, &buffer, buffer.count) {
            return String(cString: buffer)
        }
        return "Error: get posix thread name"
    }
}
