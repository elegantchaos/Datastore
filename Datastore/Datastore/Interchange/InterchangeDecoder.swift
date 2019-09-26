// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation



public protocol InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> SemanticValue
    
    func decodePrimitive(date: Any?) -> Date?
    func decodePrimitive(uuid: Any?) -> UUID?
    func decodePrimitive(data: Any?) -> Data?
    
    // TODO: split decode functions into small helper objects so that we can iterate them
    func decode(string: Any?, type: String?, store: Datastore) -> SemanticValue?
    func decode(integer: Any?, type: String?, store: Datastore) -> SemanticValue?
    func decode(double: Any?, type: String?, store: Datastore) -> SemanticValue?
    func decode(date: Any?, type: String?, store: Datastore) -> SemanticValue?
    func decode(data: Any?, type: String?, store: Datastore) -> SemanticValue?
    func decode(entity: Any?, type: String?, store: Datastore) -> SemanticValue?
}

public extension InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> SemanticValue {
        var decoded: SemanticValue? = nil
        if let record = value as? [String:Any] {
            let type = record[Datastore.standardNames.type] as? String
            if let string = record[Datastore.standardNames.string] {
                decoded = decode(string: string, type: type, store: store)
            } else if let integer = record[Datastore.standardNames.integer] {
                decoded = decode(integer: integer, type: type, store: store)
            } else if let double = record[Datastore.standardNames.double] {
                decoded = decode(double: double, type: type, store: store)
            } else if let date = record[Datastore.standardNames.date] {
                decoded = decode(date: date, type: type, store: store)
            } else if let entity = record[Datastore.standardNames.entity] {
                decoded = decode(entity: entity, type: type, store: store)
            } else if let data = record[Datastore.standardNames.data] {
                decoded = decode(data: data, type: type, store: store)
            }
        } else if let string = decode(string: value, type: nil, store: store) {
            decoded = string
        } else if let integer = decode(integer: value, type: nil, store: store) {
            decoded = integer
        } else if let double = decode(double: value, type: nil, store: store) {
            decoded = double
        } else if let date = decode(date: value, type: nil, store: store) {
            decoded = date
        } else if let uuid = decodePrimitive(uuid: value) {
            decoded = decode(entity: uuid, type: nil, store: store) // we assume that raw uuids refer to entities
        } else if let data = decodePrimitive(data: value) {
            decoded = decode(data: data, type: nil, store: store)
        } else if value != nil {
            print("couldn't decode \(String(describing: value))")
        }
        
        return decoded ?? SemanticValue(value)
    }
    
    
    func decode(string: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let string = string as? String {
            return SemanticValue(string, type: type ?? Datastore.standardNames.string)
        }
        return nil
    }
    
    func decode(integer: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let integer = integer as? Int {
            return SemanticValue(integer, type: type ?? Datastore.standardNames.integer)
        }
        return nil
    }
    
    func decode(double: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let double = double as? Double {
            return SemanticValue(double, type: type ?? Datastore.standardNames.double)
        }
        return nil
    }
    
    func decode(date: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let date = decodePrimitive(date: date) {
            return SemanticValue(date, type: type ?? Datastore.standardNames.date)
        }
        return nil
    }

    func decode(data: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let data = decodePrimitive(data: data) {
            return SemanticValue(data, type: type ?? Datastore.standardNames.data)
        }
        return nil
    }

    func decode(entity: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let uuid = decodePrimitive(uuid: entity) {
            return SemanticValue(EntityID(uuid: uuid), type: type ?? Datastore.standardNames.entity)
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
