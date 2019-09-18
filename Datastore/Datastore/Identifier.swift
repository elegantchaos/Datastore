// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import Logger

let identifierChannel = Channel("com.elegantchaos.datastore.identifier")

internal protocol ResolvableID {
    func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID?
    var object: NSManagedObject? { get }
}

internal struct NullCachedID: ResolvableID {
    internal func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID? {
        return nil
    }
    
    internal var object: NSManagedObject? {
        return nil
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
}

internal struct OpaqueIdentifiedID: ResolvableID {
    let uuid: String
    
    internal func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID? {
        if let object = type.withIdentifier(uuid, in: context) {
            return OpaqueCachedID(object)
        } else {
            return NullCachedID()
        }
    }
    
    internal var object: NSManagedObject? {
        identifierChannel.debug("identifier \(uuid) unresolved")
        return nil
    }
}

public class WrappedID<T: NSManagedObject> {
    var id: ResolvableID
    
    init(_ object: T) {
        self.id = OpaqueCachedID(object)
    }
    
    init(_ id: ResolvableID) {
        self.id = id
    }
    
    init(named name: String, createIfMissing: Bool) {
        self.id = OpaqueNamedID(name: name, createIfMissing: createIfMissing)
    }
    
    init(uuid: String) {
        self.id = OpaqueIdentifiedID(uuid: uuid)
    }
    
    func resolve(in context: NSManagedObjectContext) -> T? {
        if let resolved = id.resolve(in: context, as: T.self) {
            id = resolved
        }
        
        return id.object as? T
    }
}

public class GuaranteedWrappedID<T: NSManagedObject>: WrappedID<T> {
    var object: T {
        return id.object as! T
    }
}


public typealias EntityID = WrappedID<Entity>
public typealias SymbolID = WrappedID<Symbol>

public typealias GuaranteedEntityID = GuaranteedWrappedID<Entity>
public typealias GuaranteedSymbolID = GuaranteedWrappedID<Symbol>
