// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Logger

let identifierChannel = Channel("com.elegantchaos.datastore.identifier")

internal protocol ResolvableID {
    func resolve(in store: Datastore) -> ResolvableID?
    func hash(into hasher: inout Hasher)
    func equal(to: ResolvableID) -> Bool
    var object: EntityRecord? { get }
}

internal struct NullCachedID: ResolvableID {
    internal func resolve(in store: Datastore) -> ResolvableID? {
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
    
    internal func resolve(in store: Datastore) -> ResolvableID? {
        if store.context == cached.managedObjectContext {
            return nil
        } else if let object = store.context.object(with: id) as? EntityRecord {
            return OpaqueCachedID(object)
        } else {
            return NullCachedID()
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

internal struct OpaqueNamedID: ResolvableID {
    
    class Searcher: Hashable, Equatable {
        
        func find(in: NSManagedObjectContext) -> EntityRecord? { return nil }
        func hash(into hasher: inout Hasher) {
        }
        func equal(to other: Searcher) -> Bool {
            return false
        }
        static func == (lhs: OpaqueNamedID.Searcher, rhs: OpaqueNamedID.Searcher) -> Bool {
            return lhs.equal(to: rhs)
        }
        func addInitialProperties(entity: EntityRecord, store: Datastore) {
        }
    }

    class KeyValueSearcher: Searcher {
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

        override func equal(to other: Searcher) -> Bool {
            if let other = other as? KeyValueSearcher {
                return (other.value == value) && (other.key == key)
            } else {
                return false
            }
        }

        override func addInitialProperties(entity: EntityRecord, store: Datastore) {
            entity.add(value, key: key, type: .string, store: store)
        }
    }
    
    let searchers: [Searcher]
    let initialiser: EntityInitialiser?

    func hash(into hasher: inout Hasher) {
        searchers.hash(into: &hasher)
    }
    
    internal func resolve(in store: Datastore) -> ResolvableID? {
        for searcher in searchers {
            if let entity = searcher.find(in: store.context) {
                return OpaqueCachedID(entity)
            }
        }
        
        if let initialiser = initialiser {
            let entity = EntityRecord(in: store.context)
            entity.type = initialiser.type.name
            if let identifier = initialiser.identifier {
                entity.identifier = identifier
            }
            for searcher in searchers {
                searcher.addInitialProperties(entity: entity, store: store)
            }
            initialiser.properties.add(to: entity, store: store)
            return OpaqueCachedID(entity)
        } else {
            return NullCachedID()
        }
    }
    
    internal var object: EntityRecord? {
        identifierChannel.debug("identifier \(searchers) unresolved")
        return nil
    }

    func equal(to other: ResolvableID) -> Bool {
        if let other = other as? OpaqueNamedID {
            return (other.searchers == searchers)
        } else {
            return false
        }
    }
}

internal struct OpaqueIdentifiedID: ResolvableID {
    let identifier: String
    let initialiser: EntityInitialiser?
    
    internal func resolve(in store: Datastore) -> ResolvableID? {
        if let object = EntityRecord.withIdentifier(identifier, in: store.context) {
            return OpaqueCachedID(object)
        } else if let initialiser = initialiser {
            let entity = EntityRecord(in: store.context)
            entity.type = initialiser.type.name
            entity.identifier = identifier
            initialiser.properties.add(to: entity, store: store)
            return OpaqueCachedID(entity)
        } else {
            return NullCachedID()
        }
    }
    
    internal var object: EntityRecord? {
        identifierChannel.debug("identifier \(identifier) unresolved")
        return nil
    }

    func hash(into hasher: inout Hasher) {
        identifier.hash(into: &hasher)
    }

    func equal(to other: ResolvableID) -> Bool {
        if let other = other as? Self {
            return (other.identifier == identifier)
        } else {
            return false
        }
    }}

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

    func resolve(in store: Datastore) -> EntityRecord? {
        if let resolved = id.resolve(in: store) {
            id = resolved
        }
        
        return id.object
    }
}

/// A wrapped ID created by specifying a name or an identifier.
/// If the underlying object doesn't exist, it can be created during the resolution process.
public class ResolvableEntity: EntityReference {
    
    init(key: PropertyKey, value: String, initialiser: EntityInitialiser? = nil) {
        let searchers = [ OpaqueNamedID.KeyValueSearcher(key: key, value: value)]
        super.init(OpaqueNamedID(searchers: searchers, initialiser: initialiser))
    }
    
    init(identifier: String, initialiser: EntityInitialiser? = nil) {
        super.init(OpaqueIdentifiedID(identifier: identifier, initialiser: initialiser))
    }

}

/// An Entity is an `EntityReference` that is guaranteed to back an existing entity.
/// Internally it already has a resolved object pointer.
/// It also keeps a copy of the object's `identifier` and `type` which are publically
/// accessible and can be safely read from any thread/context.
public class GuaranteedEntity: EntityReference {
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

public struct Entity {
    public static func identifiedBy(_ identifier: String, initialiser: EntityInitialiser? = nil) -> ResolvableEntity {
        return ResolvableEntity(identifier: identifier, initialiser: initialiser)
    }
    
    public static func identifiedBy(_ identifier: String, createAs type: EntityType) -> ResolvableEntity {
        return ResolvableEntity(identifier: identifier, initialiser: EntityInitialiser(as: type))
    }
    
    public static func named(_ name: String, initialiser: EntityInitialiser? = nil) -> ResolvableEntity {
        return ResolvableEntity(key: .name, value: name, initialiser: initialiser)
    }

    public static func named(_ name: String, createAs type: EntityType) -> ResolvableEntity {
        return ResolvableEntity(key: .name, value: name, initialiser: EntityInitialiser(as: type))
    }

    public static func whereKey(_ key: PropertyKey, equals value: String, initialiser: EntityInitialiser? = nil) -> ResolvableEntity {
        return ResolvableEntity(key: key, value: value, initialiser: initialiser)
    }

    public static func whereKey(_ key: PropertyKey, equals value: String, createAs type: EntityType) -> ResolvableEntity {
        return ResolvableEntity(key: key, value: value, initialiser: EntityInitialiser(as: type))
    }

}
