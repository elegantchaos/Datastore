// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Logger

let identifierChannel = Channel("com.elegantchaos.datastore.identifier")

internal protocol ResolvableID {
    func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type, creationType: String?) -> ResolvableID?
    func hash(into hasher: inout Hasher)
    func equal(to: ResolvableID) -> Bool
    var object: NSManagedObject? { get }
}

internal struct NullCachedID: ResolvableID {
    internal func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type, creationType: String?) -> ResolvableID? {
        return nil
    }
    
    internal var object: NSManagedObject? {
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
    let cached: NSManagedObject
    let id: NSManagedObjectID
    
    internal init(_ object: NSManagedObject) {
        self.cached = object
        self.id = object.objectID
    }
    
    internal func resolve(in context: NSManagedObjectContext, as objectType: NSManagedObject.Type, creationType: String?) -> ResolvableID? {
        if context == cached.managedObjectContext {
            if type(of: cached) == objectType {
                return nil
            } else {
                return NullCachedID()
            }
        } else {
            let object = context.object(with: id)
            return OpaqueCachedID(object)
        }
    }
    
    internal var object: NSManagedObject? {
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
    
    internal func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type, creationType: String?) -> ResolvableID? {
        if let object = type.named(name, in: context, createIfMissing: false) {
            return OpaqueCachedID(object)
        } else if createIfMissing {
            let object = type.init(context: context)
            object.setValue(creationType, forKey: Datastore.standardNames.type)
            object.setValue(name, forKey: Datastore.standardNames.name)
            return OpaqueCachedID(object)
        } else {
            return NullCachedID()
        }
    }
    
    internal var object: NSManagedObject? {
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
    let createIfMissing: Bool
    
    internal func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type, creationType: String?) -> ResolvableID? {
        if let object = type.withIdentifier(identifier, in: context) {
            return OpaqueCachedID(object)
        } else if createIfMissing, let creationType = creationType {
            let object = type.init(context: context)
            object.setValue(creationType, forKey: Datastore.standardNames.type)
            object.setValue(identifier, forKey: Datastore.standardNames.identifier)
            return OpaqueCachedID(object)
        } else {
            return NullCachedID()
        }
    }
    
    internal var object: NSManagedObject? {
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

public class WrappedID<T: NSManagedObject>: Equatable, Hashable {
    var id: ResolvableID

    init(_ id: ResolvableID) {
        self.id = id
    }
    
    public static func == (lhs: WrappedID<T>, rhs: WrappedID<T>) -> Bool {
        return lhs.id.equal(to: rhs.id)
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    func resolve(in context: NSManagedObjectContext, as type: String?) -> T? {
        if let resolved = id.resolve(in: context, as: T.self, creationType: type) {
            id = resolved
        }
        
        return id.object as? T
    }
}

/// A wrapped ID created by specifying a name or an identifier.
/// If the underlying object doesn't exist, it can be created during the resolution process.
public class ResolvableWrappedID<T: NSManagedObject>: WrappedID<T> {
    
    public init(named name: String, createIfMissing: Bool) {
        super.init(OpaqueNamedID(name: name.lowercased(), createIfMissing: createIfMissing))
    }
    
    public init(identifier: String, createIfMissing: Bool = false) {
        super.init(OpaqueIdentifiedID(identifier: identifier, createIfMissing: createIfMissing))
    }
    
}

/// A wrapped ID created from an existing object.
public class GuaranteedWrappedID<T: NSManagedObject>: WrappedID<T> {
    public init(_ object: T) {
        super.init(OpaqueCachedID(object))
    }
    
    internal var object: T {
        return id.object as! T
    }
}

public typealias EntityID = WrappedID<EntityRecord>

public typealias ResolvableEntity = ResolvableWrappedID<EntityRecord>

/// An Entity is an `EntityID` that is guaranteed to back an existing entity.
/// Internally it already has a resolved object pointer.
/// It also keeps a copy of the object's `identifier` which is publically
/// accessible and can be safely read from any thread/context.
public class Entity: GuaranteedWrappedID<EntityRecord> {
    public let identifier: String
    
    override init(_ object: EntityRecord) {
        self.identifier = object.identifier!
        super.init(object)
    }
}

