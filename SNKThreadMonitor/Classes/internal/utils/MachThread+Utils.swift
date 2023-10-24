//
//  MachThread+Utils.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/20.
//

extension MachThread {
    
    static var current: MachThread {
        return MachThread(thread_self())
    }
    
    var basicInfo: MachBasicInfo? {
        // 获取线程基本信息
        var threadBasicInfo = thread_basic_info()
        if generate_basic_info(self, &threadBasicInfo) {
            return threadBasicInfo
        }
        return nil
    }
    var identifierInfo: MachIdentifierInfo? {
        // 获取线程标识信息
        var threadIdentifierInfo = thread_identifier_info()
        if generate_identifier_info(self, &threadIdentifierInfo) {
            return threadIdentifierInfo
        }
        return nil
    }
    var extendInfo: MachExtendedInfo? {
        // 获取线程扩展信息
        var threadExtendedInfo = thread_extended_info()
        if generate_extended_info(self, &threadExtendedInfo) {
            return threadExtendedInfo
        }
        return nil
    }
    var name: String {
        var buffer = [Int8](repeating: 0, count: 128)
        if mach_thread_get_name(self, &buffer, 128) {
            let name = String(cString: buffer)
            return name
        }
        return "Null"
    }
}

extension MachExtendedInfo {
    var name: String {
        let ccharArray = withUnsafeBytes(of: pth_name) { Array($0) }
        if let nullTerminatorIndex = ccharArray.firstIndex(of: 0) {
            let data = Data(ccharArray[..<nullTerminatorIndex])
            if let string = String(data: data, encoding: .utf8) {
                return string.count > 0 ? string : "Null"
            }
        }
        return "Error: No null terminator"
    }
}

extension MachIdentifierInfo {
    var queueName: String {
        var buffer = [Int8](repeating: 0, count: 256)
        if mach_thread_get_queue_name(self, &buffer, 256) {
            let queueName = String(cString: buffer)
            return queueName
        }
        return "Null"
    }
}
