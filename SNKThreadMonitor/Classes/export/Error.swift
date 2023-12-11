//
//  Error.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/12/8.
//

import Foundation

public enum ThreadMonitorError: Error {
    case notInitialedInMain
    case getMachThreadBoundToPThreadFailed
    case startMonitoringTwice
    case `internal`(_ info: String)
    
    public var desc: String {
        switch self {
        case .notInitialedInMain:
            return "The thread monitoring must be initiated on the main thread."
        case .getMachThreadBoundToPThreadFailed:
            return "The conversion of pthread_t to mach_port_t failed."
        case .startMonitoringTwice:
            return "The thread monitoring has already been initiated and cannot be started again. "
        case .internal(let info):
            return "An internal error occurred: \(info)"
        }
    }
}
