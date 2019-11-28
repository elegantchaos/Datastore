// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public protocol InterchangeEncoder {
    func encodePrimitive(_ date: Date?) -> Any?
    func encodePrimitive(_ data: Data?) -> Any?
    func encodePrimitive(_ uuid: UUID?) -> Any?

    func encode(_ date: DateProperty, into record: inout [String:Any])
    func encode(_ data: DataProperty, into record: inout [String:Any])
    func encode(_ string: StringProperty, into record: inout [String:Any])
    func encode(_ integer: IntegerProperty, into record: inout [String:Any])
    func encode(_ double: DoubleProperty, into record: inout [String:Any])
    func encode(_ relationship: RelationshipProperty, into record: inout [String:Any])
}

public extension InterchangeEncoder {
    func encodePrimitive(_ date: Date?) -> Any? {
        return date
    }

    func encodePrimitive(_ uuid: UUID?) -> Any? {
        return uuid
    }

    func encodePrimitive(_ data: Data?) -> Any? {
        return data
    }

    func encode(type: String?, datestamp: Date?, into record: inout [String:Any]) {
        record[SemanticKey.type.name] = type
        record[SemanticKey.datestamp.name] = encodePrimitive(datestamp)
    }
    
    func encode(_ date: DateProperty, into record: inout [String:Any]) {
        record[SemanticKey.date.name] = encodePrimitive(date.value)
        encode(type: date.type, datestamp: date.datestamp, into: &record)
    }

    func encode(_ data: DataProperty, into record: inout [String:Any]) {
        record[SemanticKey.data.name] = encodePrimitive(data.value)
        encode(type: data.type, datestamp: data.datestamp, into: &record)
    }

    func encode(_ string: StringProperty, into record: inout [String:Any]) {
        record[SemanticKey.string.name] = string.value
        encode(type: string.type, datestamp: string.datestamp, into: &record)
    }
    
    func encode(_ integer: IntegerProperty, into record: inout [String:Any]) {
        record[SemanticKey.integer.name] = integer.value
        encode(type: integer.type, datestamp: integer.datestamp, into: &record)
    }

    func encode(_ double: DoubleProperty, into record: inout [String:Any]) {
        record[SemanticKey.double.name] = double.value
        encode(type: double.type, datestamp: double.datestamp, into: &record)
    }

    func encode(_ relationship: RelationshipProperty, into record: inout [String:Any]) {
        record[SemanticKey.entity.name] = relationship.target.identifier
        encode(type: relationship.type, datestamp: relationship.datestamp, into: &record)
    }
}

public struct NullInterchangeEncoder: InterchangeEncoder {
    public init() {
    }
}

