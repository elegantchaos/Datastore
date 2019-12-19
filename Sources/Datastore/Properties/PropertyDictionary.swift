// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A dictionary containing `PropertyValue` objects.
/// The normal subscript operator accesses the `PropertyValue` object's actual value, and is read-only.
/// Other subscript operators are provided to access the type, or to get/set the raw semantic value.

public struct PropertyDictionary {
    public typealias Values = [PropertyKey:PropertyValue]
    public typealias RawValues = [PropertyKey:Any]
    
    var values: Values = [:]

    public var count: Int { return values.count }
    public var keys: Values.Keys { return values.keys }
    
    public init() {
    }
    
    public init(_ values: RawValues) {
        self.values = values.mapValues({ asValue($0) })
    }
    
//    public init?(_ values: RawValues?) {
//        guard let values = values else { return nil }
//        self.values = values.mapValues({ asValue($0) })
//    }
    
    public subscript(_ key: PropertyKey) -> Any? {
        get { return values[key]?.value }
        set { values[key] = asValue(newValue) }
    }
    
    public subscript(_ key: PropertyKey, as type: PropertyType) -> Any? {
        get { return values[key]?.value }
        set { values[key] = PropertyValue(newValue, type: type, datestamp: nil) }
    }
    
    public subscript(typeWithKey key: PropertyKey) -> PropertyType? {
        get { return values[key]?.type }
    }

    public subscript(datestampWithKey key: PropertyKey) -> Date? {
        get { return values[key]?.datestamp }
    }
    
    public subscript(valueWithKey key: PropertyKey) -> PropertyValue? {
        get { return values[key] }
        set { values[key] = newValue }
    }
    
    internal func asValue(_ value: Any?) -> PropertyValue {
        if let value = value as? PropertyValue {
            return value
        } else if let (value, type) = value as? (Any?, PropertyType) {
            return PropertyValue(value, type: type, datestamp: nil)
        } else if let (value, type) = value as? (Any?, String) {
            return PropertyValue(value, type: PropertyType(type), datestamp: nil)
        } else {
            return PropertyValue(value, type: nil, datestamp: nil)
        }
    }
    
    func add(to entity: EntityRecord, store: Datastore) -> [EntityRecord] {
        var added: [EntityRecord] = []
        for (key, value) in values {
            let newEntities = entity.add(property: key, value: value, store: store)
            added.append(contentsOf: newEntities)
        }
        return added
    }
    
    
}

extension PropertyDictionary: ExpressibleByDictionaryLiteral {
    public typealias Key = PropertyKey
    public typealias Value = Any
    
    public init(dictionaryLiteral elements: (PropertyKey, Any)...) {
        var values = Values()
        for (key, value) in elements {
            values[key] = PropertyValue(value)
        }
        self.values = values
    }
}

extension PropertyDictionary: CustomStringConvertible {
    public var description: String {
        let sortedKeys = values.keys.sorted(by: { return $0.value < $1.value })
        var string = ""
        for key in sortedKeys {
            string += "\n\(key.value):"
            if let value = self[key] {
                string += " \(value)"
            }
        }
        return string
    }
    
}
