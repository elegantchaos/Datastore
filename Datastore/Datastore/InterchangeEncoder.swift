// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public protocol InterchangeEncoder {
    func encode(date: Date?) -> Any?
}

public extension InterchangeEncoder {
    func encode(date: Date?) -> Any? {
        return date
    }
}

public struct NullInterchangeEncoder: InterchangeEncoder {
    public init() {
    }
}


public struct JSONInterchangeEncoder: InterchangeEncoder {
    static let formatter = ISO8601DateFormatter()

    public func encode(date: Date?) -> Any? {
        guard let date = date else {
            return nil
        }
        
        return ["date": JSONInterchangeEncoder.formatter.string(from: date)]
    }
}

