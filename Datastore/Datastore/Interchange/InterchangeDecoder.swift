// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation



public protocol InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> SemanticValue
    
    func decodePrimitive(date: Any?) -> Date?
    func decodePrimitive(uuid: Any?) -> UUID?
    
    // TODO: split decode functions into small helper objects so that we can iterate them
    func decode(string: Any?, type: String?, store: Datastore) -> SemanticValue?
    func decode(integer: Any?, type: String?, store: Datastore) -> SemanticValue?
    func decode(double: Any?, type: String?, store: Datastore) -> SemanticValue?
    func decode(date: Any?, type: String?, store: Datastore) -> SemanticValue?
    func decode(entity: Any?, type: String?, store: Datastore) -> SemanticValue?
}

public extension InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> SemanticValue {
        var decoded: SemanticValue? = nil
        if let record = value as? [String:Any] {
            let type = record["type"] as? String
            if let string = record["string"] {
                decoded = decode(string: string, type: type, store: store)
            } else if let integer = record["integer"] {
                decoded = decode(integer: integer, type: type, store: store)
            } else if let double = record["double"] {
                decoded = decode(double: double, type: type, store: store)
            } else if let date = record["date"] {
                decoded = decode(date: date, type: type, store: store)
            } else if let entity = record["entity"] {
                decoded = decode(entity: entity, type: type, store: store)
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
        } else if value != nil {
            print("couldn't decode \(String(describing: value))")
        }
        
        return decoded ?? store.value(value)
    }
    
    
    func decode(string: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let string = string as? String {
            return store.value(string, type: type ?? store.standardSymbols.string)
        }
        return nil
    }
    
    func decode(integer: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let integer = integer as? Int {
            return store.value(integer, type: type ?? store.standardSymbols.integer)
        }
        return nil
    }
    
    func decode(double: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let double = double as? Double {
            return store.value(double, type: type ?? store.standardSymbols.double)
        }
        return nil
    }
    
    func decode(date: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let date = decodePrimitive(date: date) {
            return store.value(date, type: type ?? store.standardSymbols.date)
        }
        return nil
    }
    
    func decode(entity: Any?, type: String?, store: Datastore) -> SemanticValue? {
        if let uuid = decodePrimitive(uuid: entity) {
            return store.value(EntityID(uuid: uuid), type: type ?? store.standardSymbols.entity)
        }
        return nil
    }
}

public struct NullInterchangeDecoder: InterchangeDecoder {
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
    
}


public struct JSONInterchangeDecoder: InterchangeDecoder {
    static let formatter = ISO8601DateFormatter()
    
    public func decodePrimitive(date: Any?) -> Date? {
        if let string = date as? String {
            return JSONInterchangeDecoder.formatter.date(from: string)
        }
        return nil
    }
    
    public func decodePrimitive(uuid: Any?) -> UUID? {
        if let string = uuid as? String {
            return UUID(uuidString: string)
        }
        return nil
    }
}

