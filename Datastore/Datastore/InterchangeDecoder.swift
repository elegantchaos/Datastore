// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation



public protocol InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> SemanticValue
    
    func decode(string: Any?, type: SymbolID?, store: Datastore) -> SemanticValue?
    func decode(integer: Any?, type: SymbolID?, store: Datastore) -> SemanticValue?
    func decode(date: Any?, type: SymbolID?, store: Datastore) -> SemanticValue?
    func decode(uuid: Any?, type: SymbolID?, store: Datastore) -> SemanticValue?
}

public extension InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> SemanticValue {
        if let record = value as? [String:Any] {
            var type: SymbolID? = nil
            if let name = record["type"] as? String {
                type = SymbolID(named: name)
            }
            
            var value: SemanticValue? = nil
            if let string = record["string"] {
                value = decode(string: string, type: type, store: store)
            } else if let integer = record["integer"] {
                value = decode(integer: integer, type: type, store: store)
            } else if let date = record["date"] {
                value = decode(date: date, type: type, store: store)
            } else if let uuid = record["entity"] {
                value = decode(uuid: uuid, type: type, store: store)
            }
            if let value = value {
                return value
            }
        }
        
        return store.value(value)
    }

    func decode(string: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let string = string as? String {
            return store.value(string, type: type)
        }
        return nil
    }
    
    func decode(integer: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let integer = integer as? Int {
            return store.value(integer, type: type)
        }
        return nil
    }
    
    func decode(date: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let date = date as? Date {
            return store.value(date, type: type)
        }
        return nil
    }
    
    func decode(uuid: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let uuid = uuid as? UUID {
            return store.value(uuid, type: type)
        }
        return nil
    }

}

public struct NullInterchangeDecoder: InterchangeDecoder {
}


public struct JSONInterchangeDecoder: InterchangeDecoder {
    static let formatter = ISO8601DateFormatter()

    public func decode(date: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let string = date as? String {
            let date = JSONInterchangeDecoder.formatter.date(from: string)
            return store.value(date, type: type)
        }
        return nil
    }
    
    public func decode(uuid: Any?, type: SymbolID?, store: Datastore) -> SemanticValue? {
        if let string = uuid as? String {
            let uuid = UUID(uuidString: string)
            return store.value(uuid, type: type)
        }
        return nil
    }
}

