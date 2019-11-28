// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Logger

let identifierChannel = Channel("com.elegantchaos.datastore.identifier")

internal protocol ResolvableID {
    func resolve(in store: Datastore, creationType: String?) -> ResolvableID?
    func hash(into hasher: inout Hasher)
    func equal(to: ResolvableID) -> Bool
    var object: EntityRecord? { get }
}

internal struct NullCachedID: ResolvableID {
    internal func resolve(in store: Datastore, creationType: String?) -> ResolvableID? {
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
    
    internal func resolve(in store: Datastore, creationType: String?) -> ResolvableID? {
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
    let createIfMissing: Bool
    
    internal func resolve(in store: Datastore, creationType: String?) -> ResolvableID? {
        if let object = EntityRecord.named(name, in: store.context, createIfMissing: false) {
            return OpaqueCachedID(object)
        } else if createIfMissing {
            let entity = EntityRecord(in: store.context)
            entity.type = creationType
            entity.add(name, key: .name, type: .string, store: store)
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
        createIfMissing.hash(into: &hasher)
    }

    func equal(to other: ResolvableID) -> Bool {
        if let other = other as? OpaqueNamedID {
            return (other.name == name) && (other.createIfMissing == createIfMissing)
        } else {
            return false
        }
    }
}

internal struct OpaqueIdentifiedID: ResolvableID {
    let identifier: String
    let initialProperties: PropertyDictionary?
    
    internal func resolve(in store: Datastore, creationType: String?) -> ResolvableID? {
        if let object = EntityRecord.withIdentifier(identifier, in: store.context) {
            return OpaqueCachedID(object)
        } else if let initialProperties = initialProperties, let creationType = creationType {
            let entity = EntityRecord(in: store.context)
            entity.type = creationType
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

public class WrappedID: Equatable, Hashable {
    var id: ResolvableID

    init(_ id: ResolvableID) {
        self.id = id
    }
    
    public static func == (lhs: WrappedID, rhs: WrappedID) -> Bool {
        return lhs.id.equal(to: rhs.id)
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    func resolve(in store: Datastore, as type: EntityType? = nil) -> EntityRecord? {
        if let resolved = id.resolve(in: store, creationType: type?.name) {
            id = resolved
        }
        
        return id.object
    }
}

/// A wrapped ID created by specifying a name or an identifier.
/// If the underlying object doesn't exist, it can be created during the resolution process.
public class ResolvableEntity: WrappedID {
    
    public init(named name: String, createIfMissing: Bool) {
        super.init(OpaqueNamedID(name: name.lowercased(), createIfMissing: createIfMissing))
    }
    
    public init(identifier: String, initialProperties: PropertyDictionary? = nil) {
        super.init(OpaqueIdentifiedID(identifier: identifier, initialProperties: initialProperties))
    }

    public init(identifier: String, createIfMissing: Bool) {
        super.init(OpaqueIdentifiedID(identifier: identifier, initialProperties: createIfMissing ? PropertyDictionary() : nil))
    }

}

/// An Entity is an `WrappedID` that is guaranteed to back an existing entity.
/// Internally it already has a resolved object pointer.
/// It also keeps a copy of the object's `identifier` which is publically
/// accessible and can be safely read from any thread/context.
public class Entity: WrappedID {
    public let identifier: String
    init(_ object: EntityRecord) {
        self.identifier = object.identifier!
        super.init(OpaqueCachedID(object))
    }

    internal var object: EntityRecord {
        return id.object!
    }
}

public typealias EntityID = WrappedID

