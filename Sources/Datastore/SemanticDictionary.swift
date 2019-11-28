// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A dictionary containing `SemanticValue` objects.
/// The normal subscript operator accesses the `SemanticValue` object's actual value, and is read-only.
/// Other subscript operators are provided to access the type, or to get/set the raw semantic value.

public struct SemanticDictionary {
    public typealias Key = SemanticKey
    public typealias Value = SemanticValue
    
    var values: [Key:Value] = [:]

    public init() {
    }
    
    public subscript(_ key: Key) -> Any? {
        get { return values[key]?.value }
        set {
            if let value = newValue as? Value {
                values[key] = value
            } else if let (value, type) = newValue as? (Any?, Key) {
                values[key] = Value(value, type: type, datestamp: nil)
            } else if let (value, type) = newValue as? (Any?, String) {
                values[key] = Value(value, type: Key(type), datestamp: nil)
            } else {
                values[key] = Value(newValue, type: nil, datestamp: nil)
            }
        }
    }
    
    public subscript(_ key: Key, as type: Key) -> Any? {
        get { return values[key]?.value }
        set { values[key] = Value(newValue, type: type, datestamp: nil) }
    }
    
    public subscript(typeWithKey key: Key) -> Key? {
        get { return values[key]?.type }
    }

    public subscript(datestampWithKey key: Key) -> Date? {
        get { return values[key]?.datestamp }
    }
    
    public subscript(valueWithKey key: Key) -> Value? {
        get { return values[key] }
        set { values[key] = newValue }
    }
    
    func add(to entity: EntityRecord, store: Datastore) {
        for (key, value) in values {
            entity.add(property: key, value: value, store: store)
        }
    }
}
