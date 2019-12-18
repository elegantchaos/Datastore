// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

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


extension EntityType {
    static let unknown: EntityType = "unknown"
    static let null: EntityType = "null"
}

public protocol EntityReferenceProtocol {
    func resolve(in store: Datastore) -> (EntityRecord, [EntityRecord])?
}

internal struct MatchedID: EntityResolver {
    let matchers: [EntityMatcher]
    let initialiser: EntityInitialiser?

    func hash(into hasher: inout Hasher) {
        matchers.hash(into: &hasher)
    }
    
    internal func resolve(in store: Datastore, for reference: EntityReference) -> ResolveResult {
        for searcher in matchers {
            if let entity = searcher.find(in: store.context) {
                return (CachedResolver(entity), [])
            }
        }
        
        if let initialiser = initialiser {
            let entity = EntityRecord(in: store.context)
            entity.type = reference.type.name
            if let identifier = reference.identifierForCreation {
                entity.identifier = identifier
            }
            for searcher in matchers {
                searcher.addInitialProperties(entity: entity, store: store)
            }
            
            let reference = CachedResolver(entity)
            var created: [EntityResolver] = [reference]
            let addedByRelationships = initialiser.properties.add(to: entity, store: store)
            if addedByRelationships.count > 0 {
                created.append(contentsOf: addedByRelationships.map({ CachedResolver($0) }))
            }
            return (reference, created)
        } else {
            return (NullResolver(), [])
        }
    }
    
    internal var object: EntityRecord? {
        identifierChannel.debug("identifier \(matchers) unresolved")
        return nil
    }

    func equal(to other: EntityResolver) -> Bool {
        if let other = other as? MatchedID {
            return (other.matchers == matchers)
        } else {
            return false
        }
    }
    
    var identifier: String { return EntityReference.unresolvedIdentifier } // TODO: try to find this from a matcher or the initial properties
    var type: EntityType { return .unknown } // TODO: try to find this from a matcher or the initial properties
    
    var isResolved: Bool { return false }
}

