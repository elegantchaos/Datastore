// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Logger

let identifierChannel = Channel("com.elegantchaos.datastore.identifier")


/// A reference to an entity in a store.
/// The reference can be passed around safely in any context/thread
/// It contains enough information to be resolved into a real `EntityRecord` by a store.
/// In some cases, resolving the reference may actually create a new entity.
open class EntityReference: Equatable, Hashable, EntityReferenceProtocol {
    static let unresolvedIdentifier = "«unresolved»"
    static let nullIdentifier = "«null»"

    /// identifier for the entity this reference represents; may not be known yet if the reference is unresolved
    public var identifier: String { resolver.identifier }
    
    /// type of the entity this reference represents; may not be known yet if the reference is unresolved
    public var type: EntityType { resolver.type }
    
    /// has this reference been resolved?
    public var isResolved: Bool { resolver.isResolved }
    
    /// fetched properties for the entity
    /// these represent the result of the operation that returned this entity; they may not represent all of
    /// the properties of the entity - just the ones that were requested; they may also no longer be the latest
    /// values for the entity
    public let properties: PropertyDictionary?

    /// object which is used internally to turn this reference into an actual `EntityRecord`
    var resolver: EntityResolver
    
    /// property updates stored for the entity
    /// these represent changes to the entities properties that we would like to make; they have no effect
    /// to the actual database until they are committed with an `add` or `update` operation
    var updates: PropertyDictionary?
    
    public required init(_ id: EntityResolver, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        self.resolver = id
        self.updates = updates
        self.properties = properties
    }
    
//    public convenience init(_ id: EntityResolver, properties: PropertyDictionary.RawValues? = nil, updates: PropertyDictionary.RawValues? = nil) {
//        self.init(id, properties: PropertyDictionary(properties), updates: PropertyDictionary(updates))
//    }
    
    public static func == (lhs: EntityReference, rhs: EntityReference) -> Bool {
        return lhs.resolver.equal(to: rhs.resolver)
    }
    
    public func hash(into hasher: inout Hasher) {
        resolver.hash(into: &hasher)
    }

    public func resolve(in store: Datastore) -> (EntityRecord, [EntityRecord])? {
        if let (resolved, created) = resolver.resolve(in: store, for: self) {
            resolver = resolved
            if let object = resolver.object {
                return (object, created.compactMap({ $0.object }))
            }
        }
        
        if let object = resolver.object {
            return (object, [])
        } else {
            return nil
        }
    }

    func makeUpdates() {
        if updates == nil {
            self.updates = PropertyDictionary()
        }
    }
    
    public func addUpdates(_ properties: PropertyDictionary) {
        self.updates = properties // TODO: should we merge with existing?
    }
    
    public subscript(_ key: PropertyKey) -> Any? {

        get {
            return updates?[key] ?? properties?[key]
        }
        
        set {
            makeUpdates()
            updates?[key] = newValue
        }
    }
    
    public subscript(_ key: PropertyKey, as type: PropertyType) -> Any? {
        get {
            return updates?[key, as: type] ?? properties?[key, as: type]
        }
        
        set {
            makeUpdates()
            updates?[key, as: type] = newValue
        }
    }
    
    public subscript(typeWithKey key: PropertyKey) -> PropertyType? {
        get {
            return updates?[typeWithKey: key] ?? properties?[typeWithKey: key]
        }
    }

    public subscript(datestampWithKey key: PropertyKey) -> Date? {
        get {
            return updates?[datestampWithKey: key] ?? properties?[datestampWithKey: key]
        }
    }
    
    public subscript(valueWithKey key: PropertyKey) -> PropertyValue? {
        get {
            return updates?[valueWithKey: key] ?? properties?[valueWithKey: key]
        }
        
        set {
            makeUpdates()
            updates?[valueWithKey: key] = newValue
        }
    }
    
    public var count: Int { return keys.count }
    
    public var keys: Set<PropertyKey> {
        var all: Set<PropertyKey>  = []
        if let keys = properties?.keys {
            all.formUnion(keys)
        }
        if let keys = updates?.keys {
            all.formUnion(keys)
        }
        return all
    }


    internal var object: EntityRecord {
        return resolver.object!
    }
    
}

/// Public entity reference API.
/// Constructs entity references from various patterns.

public struct Entity {
    public static func createAs(_ type: EntityType, with properties: PropertyDictionary? = nil) -> EntityReference { // TODO: add test
        let newIdentifier = UUID().uuidString // TODO: can we just pass an empty matcher list to always make a new entity?
        let searchers = [MatchByIdentifier(identifier: newIdentifier)]
        return InitialisingReference(MatchingResolver(matchers: searchers), type: type, updates: properties)
    }

    public static func identifiedBy(_ identifier: String, createAs type: EntityType? = nil, with properties: PropertyDictionary? = nil) -> EntityReference {
        let searchers = [MatchByIdentifier(identifier: identifier)]
        if let type = type {
            return InitialisingReference(MatchingResolver(matchers: searchers), type: type, updates: properties)
        } else {
            return EntityReference(MatchingResolver(matchers: searchers))
        }
        
    }
    
    public static func named(_ name: String, createAs type: EntityType? = nil, with properties: PropertyDictionary? = nil) -> EntityReference {
        let searchers = [MatchByValue(key: .name, value: name)]
        if let type = type {
            return InitialisingReference(MatchingResolver(matchers: searchers), type: type, updates: properties)
        } else {
            return EntityReference(MatchingResolver(matchers: searchers))
        }
    }

    public static func with(identifier: String, orName name: String, createAs type: EntityType? = nil, with properties: PropertyDictionary? = nil) -> EntityReference {
        let searchers = [MatchByIdentifier(identifier: identifier), MatchByValue(key: .name, value: name)]
        if let type = type {
            return InitialisingReference(MatchingResolver(matchers: searchers), type: type, updates: properties)
        } else {
            return EntityReference(MatchingResolver(matchers: searchers))
        }
    }

    public static func whereKey(_ key: PropertyKey, equals value: String, createAs type: EntityType? = nil, with properties: PropertyDictionary? = nil) -> EntityReference {
        let searchers = [MatchByValue(key: key, value: value)]
        if let type = type {
                return InitialisingReference(MatchingResolver(matchers: searchers), type: type, updates: properties)
            } else {
                return EntityReference(MatchingResolver(matchers: searchers))
            }
    }

}
