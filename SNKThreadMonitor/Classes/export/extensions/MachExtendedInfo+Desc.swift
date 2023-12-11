//
//  MachExtendedInfo+Desc.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/12/8.
//

import Foundation

public extension MachExtendedInfo {
    // 线程名称
    public var name: String {
        let ccharArray = withUnsafeBytes(of: pth_name) { Array($0) }
        if let nullTerminatorIndex = ccharArray.firstIndex(of: 0) {
            let data = Data(ccharArray[..<nullTerminatorIndex])
            if let string = String(data: data, encoding: .utf8) {
                return string.count > 0 ? string : "Null"
            }
        }
        return "Error: No null terminator"
    }
    // 扩展信息描述
    public var desc: [String: Any] {
        var dictionary = [String: Any]()
        let mirror = Mirror(reflecting: self)
        for (key, value) in mirror.children {
            if let key = key {
                if key == "pth_name" {
                    dictionary[key] = name
                } else {
                    dictionary[key] = value
                }
            }
        }
        return dictionary
    }
}
