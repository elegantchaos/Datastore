// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A dictionary containing `SemanticValue` objects.
/// The normal subscript operator accesses the `SemanticValue` object's actual value, and is read-only.
/// Other subscript operators are provided to access the type, or to get/set the raw semantic value.

public struct SemanticDictionary {
    var values: [String:SemanticValue] = [:]
    
    subscript(_ key: String) -> Any? {
        get { return values[key]?.value }
        set {
            if let value = newValue as? SemanticValue {
                values[key] = value
            } else if let (value, type) = newValue as? (Any?, String) {
                values[key] = SemanticValue(value, type: type, datestamp: nil)
            } else if let (value, type) = newValue as? (Any?, String) {
                values[key] = SemanticValue(value, type: type, datestamp: nil)
            } else {
                values[key] = SemanticValue(newValue, type: nil, datestamp: nil)
            }
        }
    }
    
    subscript(_ key: String, as type: String) -> Any? {
        get { return values[key]?.value }
        set { values[key] = SemanticValue(newValue, type: type, datestamp: nil) }
    }
    
    subscript(typeWithKey key: String) -> String? {
        get { return values[key]?.type }
    }

    subscript(datestampWithKey key: String) -> Date? {
        get { return values[key]?.datestamp }
    }
    
    subscript(valueWithKey key: String) -> SemanticValue? {
        get { return values[key] }
        set { values[key] = newValue }
    }
    
    func add(to entity: EntityRecord, store: Datastore) {
        for (key, value) in values {
            entity.add(property: key, value: value, store: store)
        }
    }
}
