// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A dictionary containing `PropertyValue` objects.
/// The normal subscript operator accesses the `PropertyValue` object's actual value, and is read-only.
/// Other subscript operators are provided to access the type, or to get/set the raw semantic value.

public struct PropertyDictionary {
    public typealias Key = PropertyKey
    public typealias Value = PropertyValue
    
    var values: [Key:Value] = [:]

    public var count: Int { return values.count }
    
    public init() {
    }
    
    public init(_ values: [Key:Any]) {
        self.values = values.mapValues({ asValue($0) })
    }
    
    public subscript(_ key: Key) -> Any? {
        get { return values[key]?.value }
        set { values[key] = asValue(newValue) }
    }
    
    public subscript(_ key: Key, as type: PropertyType) -> Any? {
        get { return values[key]?.value }
        set { values[key] = Value(newValue, type: type, datestamp: nil) }
    }
    
    public subscript(typeWithKey key: Key) -> PropertyType? {
        get { return values[key]?.type }
    }

    public subscript(datestampWithKey key: Key) -> Date? {
        get { return values[key]?.datestamp }
    }
    
    public subscript(valueWithKey key: Key) -> Value? {
        get { return values[key] }
        set { values[key] = newValue }
    }
    
    internal func asValue(_ value: Any?) -> Value {
        if let value = value as? Value {
            return value
        } else if let (value, type) = value as? (Any?, PropertyType) {
            return Value(value, type: type, datestamp: nil)
        } else if let (value, type) = value as? (Any?, String) {
            return Value(value, type: PropertyType(type), datestamp: nil)
        } else {
            return Value(value, type: nil, datestamp: nil)
        }
    }
    
    func add(to entity: EntityRecord, store: Datastore) {
        for (key, value) in values {
            entity.add(property: key, value: value, store: store)
        }
    }
    
    
}


extension PropertyDictionary: CustomStringConvertible {
    public var description: String {
        let sortedKeys = values.keys.sorted(by: { return $0.name < $1.name })
        var string = ""
        for key in sortedKeys {
            string += "\n\(key.name):"
            if let value = self[key] {
                string += " \(value)"
            }
        }
        return string
    }
    
}

public struct EntityInitialiser {
    let type: EntityType
    let properties: PropertyDictionary
    
    public init(as type: EntityType, properties: PropertyDictionary = PropertyDictionary()) {
        self.type = type
        self.properties = properties
    }

    public init(as type: EntityType, properties: [PropertyKey:Any]) {
        self.type = type
        self.properties = PropertyDictionary(properties)
    }

}
