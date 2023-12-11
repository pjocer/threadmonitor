//
//  MachThread+Utils.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/20.
//

public extension MachThread {
    
    public static var current: MachThread {
        return MachThread(thread_self())
    }
    
    public var isMainThread: Bool {
        return self == ThreadMonitor.shared.mainThread
    }
    
    public var basicInfo: MachBasicInfo? {
        // 获取线程基本信息
        var threadBasicInfo = thread_basic_info()
        if generate_basic_info(self, &threadBasicInfo) {
            return threadBasicInfo
        }
        return nil
    }
    public var identifierInfo: MachIdentifierInfo? {
        // 获取线程标识信息
        var threadIdentifierInfo = thread_identifier_info()
        if generate_identifier_info(self, &threadIdentifierInfo) {
            return threadIdentifierInfo
        }
        return nil
    }
    public var extendInfo: MachExtendedInfo? {
        // 获取线程扩展信息
        var threadExtendedInfo = thread_extended_info()
        if generate_extended_info(self, &threadExtendedInfo) {
            return threadExtendedInfo
        }
        return nil
    }
    public var name: String {
        // 线程名称
        var buffer = [Int8](repeating: 0, count: 128)
        if mach_thread_get_name(self, &buffer, 128) {
            let name = String(cString: buffer)
            return name
        }
        return "Null"
    }
    public var desc: String {
        // 描述信息
        var result = ""
        if let basicInfo = basicInfo {
            result += "\n\nBasic Info(\(self):\n\(basicInfo.desc)"
        }
        if let identifierInfo = identifierInfo {
            result += "\n\nIdentifier Info:\n\(identifierInfo.desc)"
        }
        if let extendInfo = extendInfo {
            result += "\n\nExtended Info:\n\(extendInfo.desc)"
        }
        return result
    }
    public var descHashable: [String: Any] {
        var result = [String: Any]()
        if let basicInfo = basicInfo {
            result["Basic Info"] = basicInfo.desc
        }
        if let identifierInfo = identifierInfo {
            result["Identifier Info"] = identifierInfo.desc
        }
        if let extendInfo = extendInfo {
            result["Extended Info"] = extendInfo.desc
        }
        return result
    }
}
