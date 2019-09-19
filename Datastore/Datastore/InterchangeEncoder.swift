// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public protocol InterchangeEncoder {
    func encode(_ date: Date?) -> Any?
    func encode(_ uuid: UUID?) -> Any?
    func encode(_ string: String?) -> Any?
    func encode(_ integer: Int64?) -> Any?
    func encode(_ entity: EntityRecord?) -> Any?
}

public extension InterchangeEncoder {
    func encode(_ date: Date?) -> Any? {
        return date
    }
    func encode(_ uuid: UUID?) -> Any? {
        return uuid
    }
    func encode(_ string: String?) -> Any? {
        return string
    }
    func encode(_ integer: Int64?) -> Any? {
        return integer
    }
    func encode(_ entity: EntityRecord?) -> Any? {
        return entity
    }
}

public struct NullInterchangeEncoder: InterchangeEncoder {
    public init() {
    }
}


public struct JSONInterchangeEncoder: InterchangeEncoder {
    static let formatter = ISO8601DateFormatter()

    public func encode(_ date: Date?) -> Any? {
        guard let date = date else {
            return nil
        }
        
        return ["date": JSONInterchangeEncoder.formatter.string(from: date)]
    }

    public func encode(_ uuid: UUID?) -> Any? {
        guard let uuid = uuid else {
            return nil
        }
        
        return uuid.uuidString
    }

    public func encode(_ entity: EntityRecord?) -> Any? {
        guard let uuid = entity?.uuid else {
            return nil
        }
        
        return ["entity": uuid.uuidString]
    }
}

