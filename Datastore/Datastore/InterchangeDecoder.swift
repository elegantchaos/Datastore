// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct TypedValue {
    let value: Any?
    let type: SymbolID
    
    public func coerced<T>(or defaultValue: @autoclosure () -> T) -> T {
        return (value as? T) ?? defaultValue()
    }
}

public struct TypedDictionary {
    var values: [String:TypedValue] = [:]
    subscript(_ key: String) -> Any? {
        get { return values[key]?.value }
    }
    subscript(typeWithKey key: String) -> SymbolID? {
        get { return values[key]?.type }
    }
    subscript(valueWithKey key: String) -> TypedValue? {
        get { return values[key] }
        set { values[key] = newValue }
    }
    //    subscript(_ key: String) -> TypedValue? {
    //        get { return values[key] }
    //        set { values[key] = newValue }
    //    }
}

public protocol InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> TypedValue
}

public extension InterchangeDecoder {
}

public struct NullInterchangeDecoder: InterchangeDecoder {
    public func decode(_ value: Any?, store: Datastore) -> TypedValue {
        return store.value(value)
    }
}


public struct JSONInterchangeDecoder: InterchangeDecoder {
    static let formatter = ISO8601DateFormatter()
    
    public func decode(_ value: Any?, store: Datastore) -> TypedValue {
        var decoded = value
        var type: SymbolID? = nil
        if let record = value as? [String:Any] {
            if let date = record["date"] as? String {
                decoded = JSONInterchangeDecoder.formatter.date(from: date) as Any
                type = SymbolID(named: "date")
            }
        }
        
        return store.value(decoded, type: type)
    }
    
}

