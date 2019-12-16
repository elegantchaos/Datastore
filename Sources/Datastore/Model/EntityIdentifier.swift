// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Logger

let identifierChannel = Channel("com.elegantchaos.datastore.identifier")


/// Helper object which can match against entities in the database.
internal class EntityMatcher: Hashable, Equatable {
    
    func find(in: NSManagedObjectContext) -> EntityRecord? { return nil }
    func hash(into hasher: inout Hasher) {
    }
    func equal(to other: EntityMatcher) -> Bool {
        return false
    }
    static func == (lhs: EntityMatcher, rhs: EntityMatcher) -> Bool {
        return lhs.equal(to: rhs)
    }
    func addInitialProperties(entity: EntityRecord, store: Datastore) {
    }
}


/// Matcher which finds an entity with a given identifier.
internal class MatchByIdentifier: EntityMatcher {
    let identifier: String
    init(identifier: String) {
        self.identifier = identifier
    }

    override func hash(into hasher: inout Hasher) {
        identifier.hash(into: &hasher)
    }

    override func find(in context: NSManagedObjectContext) -> EntityRecord? {
        if let object = EntityRecord.withIdentifier(identifier, in: context) {
            return object
        }
        
        return nil
    }

    override func equal(to other: EntityMatcher) -> Bool {
        if let other = other as? MatchByIdentifier {
            return (other.identifier == identifier)
        } else {
            return false
        }
    }

    override func addInitialProperties(entity: EntityRecord, store: Datastore) {
        entity.identifier = identifier
    }
}

/// Matcher which finds an entity where a given key equals a given value
internal class MatchByValue: EntityMatcher {
    let key: PropertyKey
    let value: String
    init(key: PropertyKey, value: String) {
        self.key = key
        self.value = value
    }

    override func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
        key.hash(into: &hasher)
    }

    override func find(in context: NSManagedObjectContext) -> EntityRecord? {
        // TODO: optimise this search to just fetch the newest string record with the relevant key
        let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
        if let entities = try? context.fetch(request) {
            for entity in entities {
                if let found = entity.string(withKey: key), found == value {
                    return entity
                }
            }
        }
        return nil
    }

    override func equal(to other: EntityMatcher) -> Bool {
        if let other = other as? MatchByValue {
            return (other.value == value) && (other.key == key)
        } else {
            return false
        }
    }

    override func addInitialProperties(entity: EntityRecord, store: Datastore) {
        entity.add(value, key: key, type: .string, store: store)
    }
}

internal typealias ResolveResult = (ResolvableID, [ResolvableID])?

internal protocol ResolvableID {
    func resolve(in store: Datastore) -> ResolveResult
    func hash(into hasher: inout Hasher)
    func equal(to: ResolvableID) -> Bool
    var object: EntityRecord? { get }
}

internal struct NullCachedID: ResolvableID {
    internal func resolve(in store: Datastore) -> ResolveResult {
        return nil
    }
    
    internal var object: EntityRecord? {
        return nil
    }

    func hash(into hasher: inout Hasher) {
        0.hash(into: &hasher)
    }
    
    func equal(to other: ResolvableID) -> Bool {
        return other is NullCachedID
    }
}

internal struct OpaqueCachedID: ResolvableID {
    let cached: EntityRecord
    let id: NSManagedObjectID
    
    internal init(_ object: EntityRecord) {
        self.cached = object
        self.id = object.objectID
    }
    
    internal func resolve(in store: Datastore) -> ResolveResult {
        if store.context == cached.managedObjectContext {
            return nil
        } else if let object = store.context.object(with: id) as? EntityRecord {
            return (OpaqueCachedID(object), [])
        } else {
            return (NullCachedID(), [])
        }
    }
    
    internal var object: EntityRecord? {
        return cached
    }

    func hash(into hasher: inout Hasher) {
        cached.hash(into: &hasher)
    }

    func equal(to other: ResolvableID) -> Bool {
        if let other = other as? OpaqueCachedID {
            return (other.cached == cached) || (other.id == id)
        } else {
            return false
        }
    }
}


internal struct MatchedID: ResolvableID {
    let matchers: [EntityMatcher]
    let initialiser: EntityInitialiser?

    func hash(into hasher: inout Hasher) {
        matchers.hash(into: &hasher)
    }
    
    internal func resolve(in store: Datastore) -> ResolveResult {
        for searcher in matchers {
            if let entity = searcher.find(in: store.context) {
                return (OpaqueCachedID(entity), [])
            }
        }
        
        if let initialiser = initialiser {
            let entity = EntityRecord(in: store.context)
            entity.type = initialiser.type.name
            if let identifier = initialiser.identifier {
                entity.identifier = identifier
            }
            for searcher in matchers {
                searcher.addInitialProperties(entity: entity, store: store)
            }
            
            let reference = OpaqueCachedID(entity)
            var created: [ResolvableID] = [reference]
            let addedByRelationships = initialiser.properties.add(to: entity, store: store)
            if addedByRelationships.count > 0 {
                created.append(contentsOf: addedByRelationships.map({ OpaqueCachedID($0) }))
            }
            return (reference, created)
        } else {
            return (NullCachedID(), [])
        }
    }
    
    internal var object: EntityRecord? {
        identifierChannel.debug("identifier \(matchers) unresolved")
        return nil
    }

    func equal(to other: ResolvableID) -> Bool {
        if let other = other as? MatchedID {
            return (other.matchers == matchers)
        } else {
            return false
        }
    }
}

/// A reference to an entity in a store.
/// The reference can be passed around safely in any context/thread
/// It contains enough information to be resolved into a real `EntityRecord` by a store.
/// In some cases, resolving the reference may actually create a new entity.
public class EntityReference: Equatable, Hashable {
    var id: ResolvableID

    init(_ id: ResolvableID) {
        self.id = id
    }
    
    public static func == (lhs: EntityReference, rhs: EntityReference) -> Bool {
        return lhs.id.equal(to: rhs.id)
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    func resolve(in store: Datastore) -> (EntityRecord, [EntityRecord])? {
        if let (resolved, created) = id.resolve(in: store) {
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
}

/// An Entity is an `EntityReference` that is guaranteed to back an existing entity.
/// Internally it already has a resolved object pointer.
/// It also keeps a copy of the object's `identifier` and `type` which are publically
/// accessible and can be safely read from any thread/context.
public class GuaranteedReference: EntityReference {
    public let identifier: String
    public let type: EntityType
    init(_ object: EntityRecord) {
        self.identifier = object.identifier!
        self.type = EntityType(object.type!)
        super.init(OpaqueCachedID(object))
    }

    internal var object: EntityRecord {
        return id.object!
    }
}

/// Public entity reference API.
/// Constructs entity references from various patterns.

public struct Entity {
    public static func createAs(_ type: EntityType) -> EntityReference { // TODO: add test
        let newIdentifier = UUID().uuidString // TODO: can we just pass an empty matcher list to always make a new entity?
        let searchers = [MatchByIdentifier(identifier: newIdentifier)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: EntityInitialiser(as: type)))
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
    
    public static func identifiedBy(_ identifier: String, createAs type: EntityType? = nil, with properties: [PropertyKey:Any]? = nil) -> EntityReference {
        let searchers = [MatchByIdentifier(identifier: identifier)]
        let initialiser: EntityInitialiser?
        if let type = type {
            initialiser = EntityInitialiser(as: type, properties: PropertyDictionary(properties ?? [:]))
        } else {
            initialiser = nil
        }
        
        return EntityReference(MatchedID(matchers: searchers, initialiser: initialiser))
    }
    
    public static func named(_ name: String, initialiser: EntityInitialiser? = nil) -> EntityReference {
        let searchers = [MatchByValue(key: .name, value: name)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: initialiser))
    }

    public static func named(_ name: String, createAs type: EntityType) -> EntityReference {
        let searchers = [MatchByValue(key: .name, value: name)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: EntityInitialiser(as: type)))
    }

    public static func with(identifier: String, orName name: String, initialiser: EntityInitialiser? = nil) -> EntityReference {
        let searchers = [MatchByIdentifier(identifier: identifier), MatchByValue(key: .name, value: name)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: initialiser))
    }

    public static func with(identifier: String, orName name: String, createAs type: EntityType) -> EntityReference {
        let searchers = [MatchByIdentifier(identifier: identifier), MatchByValue(key: .name, value: name)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: EntityInitialiser(as: type)))
    }

    public static func whereKey(_ key: PropertyKey, equals value: String, initialiser: EntityInitialiser? = nil) -> EntityReference {
        let searchers = [MatchByValue(key: key, value: value)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: initialiser))
    }

    public static func whereKey(_ key: PropertyKey, equals value: String, createAs type: EntityType) -> EntityReference {
        let searchers = [ MatchByValue(key: key, value: value)]
        return EntityReference(MatchedID(matchers: searchers, initialiser: EntityInitialiser(as: type)))
    }

}
