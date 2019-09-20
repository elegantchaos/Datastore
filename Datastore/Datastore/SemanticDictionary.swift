// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 19/09/2019.
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
            } else {
                values[key] = SemanticValue(value: newValue, type: nil)
            }
        }
    }

    subscript(typeWithKey key: String) -> SymbolID? {
        get { return values[key]?.type }
    }

    subscript(valueWithKey key: String) -> SemanticValue? {
        get { return values[key] }
        set { values[key] = newValue }
    }
    
    func add(to entity: EntityRecord, store: Datastore) {
        for (key, value) in values {
            entity.add(property: SymbolID(named: key), value: value, store: store)
        }
    }
}
