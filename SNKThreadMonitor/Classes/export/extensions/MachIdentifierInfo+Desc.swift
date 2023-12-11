//
//  MachIdentifierInfo+Desc.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/12/8.
//

import Foundation

public extension MachIdentifierInfo {
    // 所处队列名称
    public var queueName: String {
        var buffer = [Int8](repeating: 0, count: 256)
        if mach_thread_get_queue_name(self, &buffer, 256) {
            let queueName = String(cString: buffer)
            return queueName
        }
        return "Null"
    }
    // 标识信息描述
    public var desc: [String: Any] {
        var dictionary = [String: Any]()
        let mirror = Mirror(reflecting: self)
        for (key, value) in mirror.children {
            if let key = key {
                dictionary[key] = value
            }
        }
        dictionary["queue_name"] = queueName
        return dictionary
    }
}
