// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public protocol InterchangeEncoder {
    func encodePrimitive(_ date: Date?) -> Any?
    func encodePrimitive(_ uuid: UUID?) -> Any?

    func encode(_ date: DateProperty, into record: inout [String:Any])
    func encode(_ symbol: SymbolRecord, into record: inout [String:Any])
    func encode(_ string: StringProperty, into record: inout [String:Any])
    func encode(_ integer: IntegerProperty, into record: inout [String:Any])
    func encode(_ relationship: RelationshipProperty, into record: inout [String:Any])
}

public extension InterchangeEncoder {
    func encodePrimitive(_ date: Date?) -> Any? {
        return date
    }

    func encodePrimitive(_ uuid: UUID?) -> Any? {
        return uuid
    }

    func encode(type: SymbolRecord?, into record: inout [String:Any]) {
        record["type"] = encodePrimitive(type?.uuid)
    }
    
    func encode(_ date: DateProperty, into record: inout [String:Any]) {
        record["date"] = encodePrimitive(date.value)
        encode(type: date.type, into: &record)
    }
    
    func encode(_ symbol: SymbolRecord, into record: inout [String:Any]) {
        record["uuid"] = encodePrimitive(symbol.uuid)
    }
    
    func encode(_ string: StringProperty, into record: inout [String:Any]) {
        if let string = string.value {
            record["string"] = string
        }
        encode(type: string.type, into: &record)
    }
    
    func encode(_ integer: IntegerProperty, into record: inout [String:Any]) {
        record["integer"] = integer.value
        encode(type: integer.type, into: &record)
    }
    
    func encode(_ relationship: RelationshipProperty, into record: inout [String:Any]) {
        if let value = relationship.target?.uuid {
            record["entity"] = encodePrimitive(value)
        }
        encode(type: relationship.type, into: &record)
    }
}

public struct NullInterchangeEncoder: InterchangeEncoder {
    public init() {
    }
}


public struct JSONInterchangeEncoder: InterchangeEncoder {
    static let formatter = ISO8601DateFormatter()

    public func encodePrimitive(_ date: Date?) -> Any? {
        guard let date = date else {
            return nil
        }
        
        return JSONInterchangeEncoder.formatter.string(from: date)
    }

    public func encodePrimitive(_ uuid: UUID?) -> Any? {
        return uuid?.uuidString
    }
}

