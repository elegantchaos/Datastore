// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Logger

let identifierChannel = Channel("com.elegantchaos.datastore.identifier")

internal protocol ResolvableID {
    func resolve(in store: Datastore, as type: EntityType?) -> ResolvableID?
    func hash(into hasher: inout Hasher)
    func equal(to: ResolvableID) -> Bool
    var object: EntityRecord? { get }
}

internal struct NullCachedID: ResolvableID {
    internal func resolve(in store: Datastore, as type: EntityType?) -> ResolvableID? {
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
    
    internal func resolve(in store: Datastore, as type: EntityType?) -> ResolvableID? {
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
    let name: String
    let key: PropertyKey
    let initialProperties: PropertyDictionary?

    internal func resolve(in store: Datastore, as type: EntityType?) -> ResolvableID? {
        
        // TODO: optimise this search to just fetch the newest string record with the relevant key
        let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: store.context)
        if let entities = try? store.context.fetch(request) {
            for entity in entities {
                if let value = entity.string(withKey: key), value == name {
                    return OpaqueCachedID(entity)
                }
            }
        }

        if let initialProperties = initialProperties, let typeName = type?.name {
            let entity = EntityRecord(in: store.context)
            entity.type = typeName
            initialProperties.add(to: entity, store: store)
            entity.add(name, key: key, type: .string, store: store)
            return OpaqueCachedID(entity)
        } else {
            return NullCachedID()
        }
    }
    
    internal var object: EntityRecord? {
        identifierChannel.debug("identifier \(name) unresolved")
        return nil
    }

    func hash(into hasher: inout Hasher) {
        name.hash(into: &hasher)
        key.hash(into: &hasher)
    }

    func equal(to other: ResolvableID) -> Bool {
        if let other = other as? OpaqueNamedID {
            return (other.name == name) && (other.key == key)
        } else {
            return false
        }
    }
}

internal struct OpaqueIdentifiedID: ResolvableID {
    let identifier: String
    let initialProperties: PropertyDictionary?
    
    internal func resolve(in store: Datastore, as type: EntityType?) -> ResolvableID? {
        if let object = EntityRecord.withIdentifier(identifier, in: store.context) {
            return OpaqueCachedID(object)
        } else if let initialProperties = initialProperties, let typeName = type?.name {
            let entity = EntityRecord(in: store.context)
            entity.type = typeName
            entity.identifier = identifier
            initialProperties.add(to: entity, store: store)
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

    func resolve(in store: Datastore, as type: EntityType? = nil) -> EntityRecord? {
        if let resolved = id.resolve(in: store, as: type) {
            id = resolved
        }
        
        return id.object
    }
}

/// A wrapped ID created by specifying a name or an identifier.
/// If the underlying object doesn't exist, it can be created during the resolution process.
public class ResolvableEntity: EntityReference {
    
    init(key: PropertyKey, value: String, initialProperties: PropertyDictionary? = nil) {
        super.init(OpaqueNamedID(name: value, key: key, initialProperties: initialProperties))
    }
    
    init(identifier: String, initialProperties: PropertyDictionary? = nil) {
        super.init(OpaqueIdentifiedID(identifier: identifier, initialProperties: initialProperties))
    }

}

/// An Entity is an `EntityReference` that is guaranteed to back an existing entity.
/// Internally it already has a resolved object pointer.
/// It also keeps a copy of the object's `identifier` which is publically
/// accessible and can be safely read from any thread/context.
public class GuaranteedEntity: EntityReference {
    public let identifier: String
    init(_ object: EntityRecord) {
        self.identifier = object.identifier!
        super.init(OpaqueCachedID(object))
    }

    internal var object: EntityRecord {
        return id.object!
    }
}

public struct Entity {
    public static func identifiedBy(_ identifier: String, initialProperties: PropertyDictionary? = nil) -> ResolvableEntity {
        return ResolvableEntity(identifier: identifier, initialProperties: initialProperties)
    }
    
    public static func identifiedBy(_ identifier: String, createIfMissing: Bool) -> ResolvableEntity {
        return ResolvableEntity(identifier: identifier, initialProperties: createIfMissing ? PropertyDictionary() : nil)
    }
    
    public static func named(_ name: String, initialProperties: PropertyDictionary? = nil) -> ResolvableEntity {
        return ResolvableEntity(key: .name, value: name, initialProperties: initialProperties)
    }

    public static func named(_ name: String, createIfMissing: Bool) -> ResolvableEntity {
        return ResolvableEntity(key: .name, value: name, initialProperties: createIfMissing ? PropertyDictionary() : nil)
    }

    public static func whereKey(_ key: PropertyKey, equals value: String, initialProperties: PropertyDictionary? = nil) -> ResolvableEntity {
        return ResolvableEntity(key: key, value: value, initialProperties: initialProperties)
    }

    public static func whereKey(_ key: PropertyKey, equals value: String, createIfMissing: Bool) -> ResolvableEntity {
        return ResolvableEntity(key: key, value: value, initialProperties: createIfMissing ? PropertyDictionary() : nil)
    }

}
