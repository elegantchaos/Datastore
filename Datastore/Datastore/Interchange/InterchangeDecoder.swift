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
    func decode(string: Any?, type: SymbolID?, store: Datastore) -> SemanticValue?
    func decode(integer: Any?, type: SymbolID?, store: Datastore) -> SemanticValue?
    func decode(date: Any?, type: SymbolID?, store: Datastore) -> SemanticValue?
    func decode(entity: Any?, type: SymbolID?, store: Datastore) -> SemanticValue?
}

public extension InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> SemanticValue {
        var decoded: SemanticValue? = nil
        if let record = value as? [String:Any] {
            var type: SymbolID? = nil
            if let name = record["type"] as? String {
                type = SymbolID(named: name)
            }
            
            if let string = record["string"] {
                decoded = decode(string: string, type: type, store: store)
            } else if let integer = record["integer"] {
                decoded = decode(integer: integer, type: type, store: store)
            } else if let date = record["date"] {
                decoded = decode(date: date, type: type, store: store)
            } else if let entity = record["entity"] {
                decoded = decode(entity: entity, type: type, store: store)
            }
        } else if let string = decode(string: value, type: nil, store: store) {
            decoded = string
        } else if let integer = decode(integer: value, type: nil, store: store) {
            decoded = integer
        } else if let date = decode(date: value, type: nil, store: store) {
            decoded = date
        } else if let uuid = decodePrimitive(uuid: value) {
            decoded = decode(entity: uuid, type: nil, store: store) // we assume that raw uuids refer to entities
        }
        
        return decoded ?? store.value(value)
    }
    
    
    func decode(string: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let string = string as? String {
            return store.value(string, type: type ?? store.stringSymbol)
        }
        return nil
    }
    
    func decode(integer: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let integer = integer as? Int {
            return store.value(integer, type: type ?? store.numberSymbol)
        }
        return nil
    }
    
    func decode(date: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let date = decodePrimitive(date: date) {
            return store.value(date, type: type ?? store.dateSymbol)
        }
        return nil
    }
    
    func decode(entity: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let uuid = decodePrimitive(uuid: entity) {
            return store.value(EntityID(uuid: uuid), type: type ?? store.entitySymbol)
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

