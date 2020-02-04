// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation



public protocol InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> PropertyValue
    
    func decodePrimitive(date: Any?) -> Date?
    func decodePrimitive(uuid: Any?) -> UUID?
    func decodePrimitive(data: Any?) -> Data?
    
    // TODO: split decode functions into small helper objects so that we can iterate them
    func decode(string: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue?
    func decode(integer: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue?
    func decode(double: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue?
    func decode(boolean: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue?
    func decode(date: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue?
    func decode(data: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue?
    func decode(entity: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue?
}

public extension InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> PropertyValue {
        var decoded: PropertyValue? = nil
        if let record = value as? [String:Any] {
            let typeName = record[PropertyKey.type.value] as? String
            let type = DatastoreType(typeName)
            if let string = record[DatastoreType.string.name] {
                decoded = decode(string: string, type: type, store: store)
            } else if let integer = record[DatastoreType.integer.name] {
                decoded = decode(integer: integer, type: type, store: store)
            } else if let double = record[DatastoreType.double.name] {
                decoded = decode(double: double, type: type, store: store)
            } else if let boolean = record[DatastoreType.boolean.name] {
                decoded = decode(boolean: boolean, type: type, store: store)
            } else if let date = record[DatastoreType.date.name] {
                decoded = decode(date: date, type: type, store: store)
            } else if let entity = record[DatastoreType.entity.name] {
                decoded = decode(entity: entity, type: type, store: store)
            } else if let data = record[DatastoreType.data.name] {
                decoded = decode(data: data, type: type, store: store)
            }
        } else if let string = decode(string: value, type: nil, store: store) {
            decoded = string
        } else if let integer = decode(integer: value, type: nil, store: store) {
            decoded = integer
        } else if let double = decode(double: value, type: nil, store: store) {
            decoded = double
        } else if let boolean = decode(boolean: value, type: nil, store: store) {
            decoded = boolean
        } else if let date = decode(date: value, type: nil, store: store) {
            decoded = date
        } else if let uuid = decodePrimitive(uuid: value) {
            decoded = decode(entity: uuid.uuidString, type: nil, store: store) // we assume that raw uuids refer to entities
        } else if let data = decodePrimitive(data: value) {
            decoded = decode(data: data, type: nil, store: store)
        } else if value != nil {
            print("couldn't decode \(String(describing: value))")
        }
        
        return decoded ?? PropertyValue(value)
    }
    
    
    func decode(string: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue? {
        if let string = string as? String {
            return PropertyValue(string, type: type ?? .string)
        }
        return nil
    }

    func decode(boolean: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue? {
        if let boolean = boolean as? Bool {
            return PropertyValue(boolean, type: type ?? .boolean)
        }
        return nil
    }

    func decode(integer: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue? {
        if let integer = integer as? Int {
            return PropertyValue(integer, type: type ?? .integer)
        }
        return nil
    }
    
    func decode(double: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue? {
        if let double = double as? Double {
            return PropertyValue(double, type: type ?? .double)
        }
        return nil
    }
    
    func decode(date: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue? {
        if let date = decodePrimitive(date: date) {
            return PropertyValue(date, type: type ?? .date)
        }
        return nil
    }

    func decode(data: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue? {
        if let data = decodePrimitive(data: data) {
            return PropertyValue(data, type: type ?? .data)
        }
        return nil
    }

    func decode(entity: Any?, type: DatastoreType?, store: Datastore) -> PropertyValue? {
        if let identifier = entity as? String {
            return PropertyValue(Entity.identifiedBy(identifier), type: type ?? .entity)
        }
        return nil
    }
}

public struct BasicInterchangeDecoder: InterchangeDecoder {
    public func decodePrimitive(date: Any?) -> Date? {
        return date as? Date
    }
    
    public func decodePrimitive(uuid value: Any?) -> UUID? {
        switch value {
        case let uuid as UUID:
            return uuid
        case let string as String:
            return UUID(uuidString: string)
        default:
            return nil
        }
    }
    
    public func decodePrimitive(data: Any?) -> Data? {
        return data as? Data
    }
}
