// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Logger

let identifierChannel = Channel("com.elegantchaos.datastore.identifier")

internal protocol ResolvableID {
    func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID?
    func hash(into hasher: inout Hasher)
    func equal(to: ResolvableID) -> Bool
    var object: NSManagedObject? { get }
}

internal struct NullCachedID: ResolvableID {
    internal func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID? {
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
    
    internal func resolve(in context: NSManagedObjectContext, as objectType: NSManagedObject.Type) -> ResolvableID? {
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
    
    internal func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID? {
        if let object = type.named(name, in: context, createIfMissing: createIfMissing) {
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
    
    internal func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID? {
        if let object = type.withIdentifier(identifier, in: context) {
            return OpaqueCachedID(object)
        } else if createIfMissing {
            let object = type.init(context: context)
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
    
    init(_ object: T) {
        self.id = OpaqueCachedID(object)
    }
    
    init(_ id: ResolvableID) {
        self.id = id
    }
    
    public init(named name: String, createIfMissing: Bool) {
        self.id = OpaqueNamedID(name: name.lowercased(), createIfMissing: createIfMissing)
    }
    
    public init(identifier: String, createIfMissing: Bool = false) {
        self.id = OpaqueIdentifiedID(identifier: identifier, createIfMissing: createIfMissing)
    }
    
    func resolve(in context: NSManagedObjectContext) -> T? {
        if let resolved = id.resolve(in: context, as: T.self) {
            id = resolved
        }
        
        return id.object as? T
    }

    public static func == (lhs: WrappedID<T>, rhs: WrappedID<T>) -> Bool {
        return lhs.id.equal(to: rhs.id)
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}

public class GuaranteedWrappedID<T: NSManagedObject>: WrappedID<T> {
    internal var object: T {
        return id.object as! T
    }
}

public typealias EntityID = WrappedID<EntityRecord>
public typealias Entity = GuaranteedWrappedID<EntityRecord>

