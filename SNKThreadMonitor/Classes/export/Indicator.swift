//
//  Indicator.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/10/20.
//

import Foundation

protocol IndicatorType {
    var name: String { get }
    var callStacks: [String] { get }
    var desc: String { get }
}

enum Indicator {
//    case deadLoad(_ )
}

