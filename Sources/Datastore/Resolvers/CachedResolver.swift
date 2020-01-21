// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

/// Resolves to a cached `EntityRecord` that we know exists.
/// If we're asked to resolve using the same context as the cached object, we can just return the object.
/// Otherwise we use the core data identifier of the cached object to find its equivalent in the other context.
/// We cache a copy of the identifier and type when we're created, so that they can be safely read from any thread.

internal struct CachedResolver: EntityResolver {
    let cached: EntityRecord
    let id: NSManagedObjectID
    let identifier: String
    let type: EntityType
    
    internal init(_ object: EntityRecord) {
        self.cached = object
        self.id = object.objectID
        self.identifier = object.identifier!
        self.type = EntityType(object.type!)
    }
    
    internal func resolve(in store: Datastore, for reference: EntityReference) -> ResolveResult {
        if store.context == cached.managedObjectContext {
            return nil
        } else if let object = store.context.object(with: id) as? EntityRecord {
            return (CachedResolver(object), [])
        } else {
            return (NullResolver(), [])
        }
    }
    
    internal var object: EntityRecord? {
        return cached
    }

    func hash(into hasher: inout Hasher) {
        cached.hash(into: &hasher)
    }

    func equal(to other: EntityResolver) -> Bool {
        if let other = other as? CachedResolver {
            return (other.cached == cached) || (other.id == id)
        } else {
            return false
        }
    }
    
    var isResolved: Bool {
        return true
    }
}

