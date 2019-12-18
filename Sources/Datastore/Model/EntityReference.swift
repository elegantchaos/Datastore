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

    var id: EntityResolver
    var updates: PropertyDictionary?

    public var identifier: String { id.identifier ?? EntityReference.unresolvedIdentifier }
    public var type: EntityType { id.type }
    public var identifierForCreation: String? { return nil}

    public let properties: PropertyDictionary?
    
    public required init(_ id: EntityResolver, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        self.id = id
        self.updates = updates
        self.properties = properties
    }
    
    public static func == (lhs: EntityReference, rhs: EntityReference) -> Bool {
        return lhs.id.equal(to: rhs.id)
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    public func resolve(in store: Datastore) -> (EntityRecord, [EntityRecord])? {
        if let (resolved, created) = id.resolve(in: store, for: self) {
            id = resolved
            if let object = id.object {
                return (object, created.compactMap({ $0.object }))
            }
        }
        
        if let object = id.object {
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
        return id.object!
    }
    
}

class TypedReference: EntityReference {
    let storedType: EntityType
    let initialIdentifier: String?
    
    override var type: EntityType { return storedType }
    override var identifier: String { return initialIdentifier ?? super.identifier }
    override var identifierForCreation: String? { return initialIdentifier }
    
    required init(_ id: EntityResolver, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        fatalError("typed reference created without type")
    }

    init(_ id: EntityResolver, type: EntityType, initialIdentifier: String? = nil, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        self.storedType = type
        self.initialIdentifier = initialIdentifier
        super.init(id, properties: properties, updates: updates)
    }
}


open class CustomReference: EntityReference {
    class open func staticType() -> EntityType { return EntityType("unknown-type") }
    
    override public var type: EntityType { return Swift.type(of: self).staticType() }
    
    public required init(_ id: EntityResolver, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        super.init(id, properties: properties, updates: updates)
    }
    
    init(named name: String) {
        let searchers = [MatchByValue(key: .name, value: name)]
        super.init(MatchedID(matchers: searchers, initialiser: EntityInitialiser()))
    }
}

/// Public entity reference API.
/// Constructs entity references from various patterns.

public struct Entity {
    public static func createAs(_ type: EntityType) -> EntityReference { // TODO: add test
        let newIdentifier = UUID().uuidString // TODO: can we just pass an empty matcher list to always make a new entity?
        let searchers = [MatchByIdentifier(identifier: newIdentifier)]
        return TypedReference(MatchedID(matchers: searchers, initialiser: EntityInitialiser()), type: type)
    }

    public static func createWith(_ initialiser: EntityInitialiser) -> EntityReference { // TODO: add test
        let newIdentifier = UUID().uuidString // TODO: can we just pass an empty matcher list to always make a new entity?
        let searchers = [MatchByIdentifier(identifier: newIdentifier)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: initialiser))
    }

    public static func identifiedBy(_ identifier: String, initialiser: EntityInitialiser) -> EntityReference {
        let searchers = [MatchByIdentifier(identifier: identifier)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: initialiser))
    }
    
    public static func identifiedBy(_ identifier: String, createAs type: EntityType? = nil, initialIdentifier: String? = nil, with properties: [PropertyKey:Any]? = nil) -> EntityReference {
        let searchers = [MatchByIdentifier(identifier: identifier)]
        if let type = type {
            let initialiser = EntityInitialiser(properties: PropertyDictionary(properties ?? [:]))
            return TypedReference(MatchedID(matchers: searchers, initialiser: initialiser), type: type, initialIdentifier: initialIdentifier)
        } else {
            return EntityReference(MatchedID(matchers: searchers, initialiser: nil))
        }
        
    }
    
    public static func named(_ name: String, as type: EntityType? = nil, initialIdentifier: String? = nil, initialiser: EntityInitialiser? = nil) -> EntityReference {
        let searchers = [MatchByValue(key: .name, value: name)]
        if let type = type {
            return TypedReference(MatchedID(matchers: searchers, initialiser: initialiser), type: type, initialIdentifier: initialIdentifier)
        } else {
            return EntityReference(MatchedID(matchers: searchers, initialiser: initialiser))
        }
    }

    public static func named(_ name: String, createAs type: EntityType) -> EntityReference {
        let searchers = [MatchByValue(key: .name, value: name)]
        return TypedReference(MatchedID(matchers: searchers, initialiser: EntityInitialiser()), type: type)
    }

    public static func with(identifier: String, orName name: String, initialiser: EntityInitialiser? = nil) -> EntityReference {
        let searchers = [MatchByIdentifier(identifier: identifier), MatchByValue(key: .name, value: name)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: initialiser))
    }

    public static func with(identifier: String, orName name: String, createAs type: EntityType) -> EntityReference {
        let searchers = [MatchByIdentifier(identifier: identifier), MatchByValue(key: .name, value: name)]
        return TypedReference(MatchedID(matchers: searchers, initialiser: EntityInitialiser()), type: type)
    }

    public static func whereKey(_ key: PropertyKey, equals value: String, initialiser: EntityInitialiser? = nil) -> EntityReference {
        let searchers = [MatchByValue(key: key, value: value)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: initialiser))
    }

    public static func whereKey(_ key: PropertyKey, equals value: String, createAs type: EntityType) -> EntityReference {
        let searchers = [ MatchByValue(key: key, value: value)]
        return TypedReference(MatchedID(matchers: searchers, initialiser: EntityInitialiser()), type: type)
    }

}
