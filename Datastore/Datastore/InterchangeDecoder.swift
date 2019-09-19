// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation



public protocol InterchangeDecoder {
    func decode(_ value: Any?, store: Datastore) -> SemanticValue
}

public extension InterchangeDecoder {
}

public struct NullInterchangeDecoder: InterchangeDecoder {
    public func decode(_ value: Any?, store: Datastore) -> SemanticValue {
        return store.value(value)
    }
}


public struct JSONInterchangeDecoder: InterchangeDecoder {
    static let formatter = ISO8601DateFormatter()
    
    public func decode(_ value: Any?, store: Datastore) -> SemanticValue {
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

