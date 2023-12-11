//
//  time_value_t+Codable.swift
//  SNKThreadMonitor
//
//  Created by Jocer on 2023/12/8.
//

import Foundation

extension time_value_t: Codable {
    enum CodingKeys: String, CodingKey {
        case seconds
        case microseconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let seconds = try container.decode(integer_t.self, forKey: .seconds)
        let microseconds = try container.decode(integer_t.self, forKey: .microseconds)
        self.init(seconds: seconds, microseconds: microseconds)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(seconds, forKey: .seconds)
        try container.encode(microseconds, forKey: .microseconds)
    }
}
