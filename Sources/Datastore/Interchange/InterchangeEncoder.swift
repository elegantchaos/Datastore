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
    func encode(_ boolean: BooleanProperty, into record: inout [String:Any])
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
        record[PropertyKey.type.value] = type
        record[PropertyKey.datestamp.value] = encodePrimitive(datestamp)
    }
    
    func encode(_ date: DateProperty, into record: inout [String:Any]) {
        record[DatastoreType.date.name] = encodePrimitive(date.value)
        encode(type: date.typeName, datestamp: date.datestamp, into: &record)
    }

    func encode(_ data: DataProperty, into record: inout [String:Any]) {
        record[DatastoreType.data.name] = encodePrimitive(data.value)
        encode(type: data.typeName, datestamp: data.datestamp, into: &record)
    }

    func encode(_ string: StringProperty, into record: inout [String:Any]) {
        record[DatastoreType.string.name] = string.value
        encode(type: string.typeName, datestamp: string.datestamp, into: &record)
    }
    
    func encode(_ integer: IntegerProperty, into record: inout [String:Any]) {
        record[DatastoreType.integer.name] = integer.value
        encode(type: integer.typeName, datestamp: integer.datestamp, into: &record)
    }

    func encode(_ double: DoubleProperty, into record: inout [String:Any]) {
        record[DatastoreType.double.name] = double.value
        encode(type: double.typeName, datestamp: double.datestamp, into: &record)
    }

    func encode(_ boolean: BooleanProperty, into record: inout [String:Any]) {
        record[DatastoreType.boolean.name] = boolean.value
        encode(type: boolean.typeName, datestamp: boolean.datestamp, into: &record)
    }

    func encode(_ relationship: RelationshipProperty, into record: inout [String:Any]) {
        record[DatastoreType.entity.name] = relationship.target.identifier
        encode(type: relationship.typeName, datestamp: relationship.datestamp, into: &record)
    }
}

public struct NullInterchangeEncoder: InterchangeEncoder {
    public init() {
    }
}

