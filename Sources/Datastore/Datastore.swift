// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import Logger

let datastoreChannel = Channel("com.elegantchaos.datastore")

public extension Notification.Name {
    static let EntityChangedNotification = NSNotification.Name(rawValue: "EntityChanged")
}

public struct EntityChanges {
    public enum Action {
        case get
        case add
        case update
        case remove
        case delete
    }
    
    public let action: Action
    public let added: Set<EntityReference>
    public let deleted: Set<EntityReference>
    public let changed: Set<EntityReference>
    public let keys: Set<PropertyKey>
}


public class Datastore {
    internal let context: NSManagedObjectContext
    internal let indexer: NSCoreDataCoreSpotlightDelegate?
    internal var classMap: [DatastoreType:EntityReference.Type]
    internal var conformanceMap: ConformanceMap

    class EntityCache {
        var index: [String:EntityRecord] = [:]
        var cacheHits = 0
        var cacheMisses = 0
        var cacheRewrites = 0
    }
    
    internal var entityCache: EntityCache?
    internal var notificationsPaused = 0



    public typealias SaveResult = Result<Void, Error>
    public typealias SaveCompletion = (SaveResult) -> Void
    public typealias EntitiesCompletion = ([EntityReference]) -> Void
    public typealias TypesCompletion = ([DatastoreType]) -> Void
    public typealias EntityCompletion = (EntityReference?) -> Void
    public typealias InterchangeCompletion = ([String:Any]) -> Void
    public typealias CountCompletion = ([Int]) -> Void
    
    struct LoadingModelError: Error { }
    struct InvalidJSONError: Error { }
    
    public typealias ApplyResult = Result<Void, Error>
    
    static let specialProperties: [PropertyKey] = [.identifier, .datestamp, .type]
    static var persistentStoreType: String { return NSSQLiteStoreType }

    public var url: URL { context.persistentStoreCoordinator!.persistentStores.first!.url! }
    
    internal class func storeOptions(withIndexer indexer: NSCoreDataCoreSpotlightDelegate? = nil) -> [String : NSObject] {
        let YES = true as NSValue
        var options: [String : NSObject] = [
            NSMigratePersistentStoresAutomaticallyOption: YES,
            NSInferMappingModelAutomaticallyOption: YES
        ]

        if let indexer = indexer {
            options[NSCoreDataCoreSpotlightExporter] = indexer
        }

        return options
    }
    
    /// Create a store instance, with a given container and indexer.
    /// - Parameters:
    ///   - container: backing container
    ///   - indexer: spotlight indexer, if required
    internal init(context: NSManagedObjectContext, indexer: NSCoreDataCoreSpotlightDelegate?) {
        self.context = context
        self.indexer = indexer
        self.classMap = [:]
        self.conformanceMap = ConformanceMap()
    }
    
    /// Save any outstanding changes to the store
    /// - Parameter completion: completion block
    public func save(completion: @escaping SaveCompletion) {
        let context = self.context
        context.perform {
            do {
                try context.save()
                completion(.success(Void()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    /// Reset the store.
    /// Removes all entities.
    /// - Parameter callback: completion block
    open func reset(callback: @escaping () -> Void) {
        context.reset()
        context.processPendingChanges()
        callback()
    }

    
    internal func makeReference(for entity: EntityRecord, properties: PropertyDictionary? = nil) -> EntityReference {
        var classToUse = EntityReference.self
        if let entityType = entity.type, let customType = classMap[DatastoreType(entityType)] {
            classToUse = customType
        }
        
        return classToUse.init(CachedResolver(entity), properties: properties)
    }

    public func register(classes: [CustomReference.Type]) {
        for classToUse in classes {
            classMap[classToUse.staticType()] = classToUse
        }
    }
    
    
    /// Get a specific entity.
    /// May create the entity if it doesn't exist and the reference has an initialiser.
    /// - Parameters:
    ///   - entity: entity to look for
    ///   - completion: completion block
    public func get(entity: EntityReference, completion: @escaping EntityCompletion) {
        get(entitiesWithIDs: [entity]) { entities in
            completion(entities.first)
        }
    }
    
    /// Get some entities.
    /// May create any entities that don't already exist, if their references have an initialiser.
    /// - Parameters:
    ///   - entityIDs: entities to look for
    ///   - completion: completion block
    public func get(entitiesWithIDs entityIDs: [EntityReferenceProtocol], completion: @escaping EntitiesCompletion) {
        let context = self.context
        var added: Set<EntityReference> = []
        context.perform {
            var result: [EntityReference] = []
            for entityID in entityIDs {
                if let (entity, wasCreated) = entityID.resolve(in: self) {
                    let reference = self.makeReference(for: entity)
                    result.append(reference)
                    if wasCreated.count > 0 {
                        added.formUnion(wasCreated.map({ self.makeReference(for: $0) }))
                    }
                }
            }
            
            self.notify(action: .get, added: added)
            completion(result)
        }
    }
    

    /// Retrieve an entity of a given type where a property matches a specific value.
    /// - Parameters:
    ///   - type: entity type to look for
    ///   - key: key to search
    ///   - equals: value to check for
    ///   - createIfMissing: should we create the entity if it isn't found?
    ///   - completion: completion block
    public func get(entityOfType type: DatastoreType, where key: PropertyKey, equals: String, createIfMissing: Bool = true, completion: @escaping EntityCompletion) {
        get(entitiesOfType: type, where: key, contains: [equals], createIfMissing: createIfMissing) { entities in
            completion(entities.first)
        }
    }
    
    
    /// Get all entities of a given type where a given property matches one of a set of values.
    /// - Parameters:
    ///   - type: the entity type to retrieve
    ///   - key: the property to filter on
    ///   - contains: the values to filter on
    ///   - createIfMissing: create entities for any values we didn't find
    ///   - completion: completion block
    public func get(entitiesOfType type: DatastoreType, where key: PropertyKey, contains: Set<String>, createIfMissing: Bool = true, completion: @escaping EntitiesCompletion) {
        let context = self.context
        
        context.perform {
            var result: [EntityReference] = []
            var create: Set<String> = contains
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
            request.predicate = NSPredicate(format: "type == %@", type.name)
            if let entities = try? context.fetch(request) {
                for entity in entities {
                    if let value = entity.string(withKey: key), contains.contains(value) {
                        result.append(self.makeReference(for: entity))
                        create.remove(value)
                    }
                }
            }
            
            var added: Set<EntityReference> = []
            if createIfMissing {
                for name in create {
                    let entity = EntityRecord(in: context)
                    entity.type = type.name
                    let property = StringProperty(in: context)
                    property.owner = entity
                    property.name = key.value
                    property.value = name
                    let reference = self.makeReference(for: entity)
                    self.addCached(identifier: entity.identifier!, entity: entity)
                    result.append(reference)
                    added.insert(reference)
                }
            }
            self.notify(action: .get, added: added)
            completion(result)
        }
    }
    
    /// Retrieve all entities of a given type
    /// - Parameters:
    ///   - type: the types to retrieve
    ///   - completion: completion block
    public func get(allEntitiesOfType type: DatastoreType, completion: @escaping EntitiesCompletion) {
        let context = self.context
        context.perform {
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
            request.predicate = NSPredicate(format: "type = %@", type.name)
            if let entities = try? context.fetch(request) {
                completion(Array(entities.map({ self.makeReference(for: $0) })))
            } else {
                completion([])
            }
        }
    }
    
    /// Count all entities of some entity types.
    /// - Parameters:
    ///   - types: the types to count
    ///   - completion: completion block
    public func count(entitiesOfTypes types: [DatastoreType], completion: @escaping CountCompletion) {
        let context = self.context
        context.perform {
            var counts: [Int] = []
            for type in types {
                let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
                request.predicate = NSPredicate(format: "type = %@", type.name)
                if let result = try? context.count(for: request) {
                    counts.append(result)
                } else {
                    counts.append(0)
                }
            }
            completion(counts)
        }
    }
    
    /// Retrieve all entities
    /// - Parameter completion: completion block
    public func getAllEntities(completion: @escaping EntitiesCompletion) {
        let context = self.context
        context.perform {
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
            if let entities = try? context.fetch(request) {
                completion(Array(entities.map({ self.makeReference(for: $0) })))
            } else {
                completion([])
            }
        }
    }

    /// Retrieve all entity types
    /// - Parameter completion: completion block
    public func getAllEntityTypes(completion: @escaping TypesCompletion) {
        let context = self.context
        context.perform {
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
            if let entities = try? context.fetch(request) {
                let typeNames = Set(entities.compactMap({ $0.type }))
                completion(Array(typeNames.map({ DatastoreType($0) })))
            } else {
                completion([])
            }
        }
    }
    
    /// Get specific property values for a group of entities
    /// - Parameters:
    ///   - keys: the property keys to retrieve
    ///   - entities: the entities to retrieve properties for
    ///   - completion: completion block
    public func get(properties names: Set<PropertyKey>, of entities: [EntityReference], completion: @escaping ([EntityReference]) -> Void) {
        get(properties: Set(names.map({ $0.value })), of: entities, completion: completion)
    }
    
    /// Get specific property values for a group of entities
    /// - Parameters:
    ///   - keys: names of the properties to retrieve
    ///   - entities: the entities to retrieve properties for
    ///   - completion: completion block
    public func get(properties names: Set<String>, of entities: [EntityReference], completion: @escaping ([EntityReference]) -> Void) {
        let context = self.context
        context.perform {
            var added: Set<EntityReference> = []
            var result: [EntityReference] = []
            for entityID in entities {
                if let (entity, wasCreated) = entityID.resolve(in: self) {
                    let values = entity.read(properties: names, store: self)
                    if wasCreated.count > 0 {
                        added.formUnion(wasCreated.map({ self.makeReference(for: $0) }))
                    }
                    result.append(self.makeReference(for: entity, properties: values))
                } else {
                    result.append(entityID)
                }
            }
            
            self.notify(action: .get, added: added)
            completion(result)
        }
    }
    
    /// Gets all the properties for some entities.
    /// - Parameters:
    ///   - entities: the entities to get properties for
    ///   - completion: completion block
    public func get(allPropertiesOf entities: [EntityReference], completion: @escaping ([EntityReference]) -> Void) {
        let context = self.context
        context.perform {
            var result: [EntityReference] = []
            var added: Set<EntityReference> = []
            for entityID in entities {
                if let (entity, wasCreated) = entityID.resolve(in: self) {
                    let values = entity.readAllProperties(store: self)
                    let refWithValues = self.makeReference(for: entity, properties: values)
                    if wasCreated.count > 0 {
                        added.formUnion(wasCreated.map({ self.makeReference(for: $0) }))
                    }
                    result.append(refWithValues)
                } else {
                    result.append(entityID)
                }
            }
            
            self.notify(action: .get, added: added)
            completion(result)
        }
    }
    
    /// Add some properties to some entities.
    /// Always creates new property records for all the added properties, even if they
    /// already existed and had the same values.
    /// - Parameters:
    ///   - properties: dictionary with entities as keys, and properties to update as values
    ///   - completion: completion block
    public func add(properties: [EntityReference], completion: @escaping () -> Void) {
        let context = self.context
        context.perform {
            var added: Set<EntityReference> = []
            var changed: Set<EntityReference> = []
            var keys: Set<PropertyKey> = []
            for entityID in properties {
                if let (entity, wasCreated) = entityID.resolve(in: self) {
                    let values = entityID.updates ?? PropertyDictionary()
                    let addedByRelationships = values.add(to: entity, store: self)
                    if addedByRelationships.count > 0 {
                        added.formUnion(addedByRelationships.map({ self.makeReference(for: $0) }))
                    }
                    let reference = self.makeReference(for: entity)
                    
                    if wasCreated.count == 0 {
                        changed.insert(reference)
                        keys.formUnion(values.values.keys)
                    } else {
                        added.formUnion(wasCreated.map({ self.makeReference(for: $0) }))
                    }
                }
            }
            
            self.notify(action: .add, added: added, changed: changed, keys: keys)
            completion()
        }
    }
    
    /// Update property values for some entities.
    /// Will only create new property records if a property value has changed (or didn't exist)
    /// - Parameters:
    ///   - properties: dictionary with entities as keys, and properties to update as values
    ///   - completion: completion block
    public func update(properties: [EntityReference], completion: @escaping () -> Void) {
        // TODO: implement this properly, so that it only creates new property entries for properties that have actually changed value
        let context = self.context
        context.perform {
            var added: Set<EntityReference> = []
            var changed: Set<EntityReference> = []
            var keys: Set<PropertyKey> = []
            for entityID in properties {
                if let (entity, wasCreated) = entityID.resolve(in: self) {
                    let values = entityID.updates ?? PropertyDictionary()
                    let addedByRelationships = values.add(to: entity, store: self)
                    if addedByRelationships.count > 0 {
                        added.formUnion(addedByRelationships.map({ self.makeReference(for:$0) }))
                    }
                    let reference = self.makeReference(for: entity)
                    
                    if wasCreated.count == 0 {
                        changed.insert(reference)
                        keys.formUnion(values.values.keys)
                    } else {
                        added.formUnion(wasCreated.map({ self.makeReference(for: $0) }))
                    }
                }
            }
            
            self.notify(action: .update, added: added, changed: changed, keys: keys)
            completion()
        }
    }
    
    /// Remove some properties from some entities
    /// - Parameters:
    ///   - names: names of the properties to remove
    ///   - entities: entities to remove from
    ///   - completion: completion block
    public func remove(properties names: Set<PropertyKey>, of entities: [EntityReference], completion: @escaping () -> Void) {
        let context = self.context
        context.perform {
            var added: Set<EntityReference> = []
            var changed: Set<EntityReference> = []
            let propertyNames = Set<String>(names.map({ $0.value }))
            for entityID in entities {
                if let (entity, wasCreated) = entityID.resolve(in: self) {
                    entity.remove(properties: propertyNames, store: self)
                    
                    // in theory, resolving the reference to an entity that we want to remove a property from
                    // could actually create it, or other entities referenced by it
                    if wasCreated.count > 0 {
                        added.formUnion(wasCreated.map({ self.makeReference(for: $0) }))
                        datastoreChannel.log("created objects during property removal - probably a mistake: \(added)")
                    }
                    
                    let reference = self.makeReference(for: entity)
                    changed.insert(reference)
                }
            }
            
            self.notify(action: .remove, changed: changed, keys: names)
            completion()
        }
    }
    
    /// Remove some entities
    /// - Parameters:
    ///   - entities: the entities to remove
    ///   - completion: completion block
    public func delete(entities: [EntityReference], completion: @escaping () -> Void) {
        let context = self.context
        context.perform {
            var added: Set<EntityReference> = []
            var deleted: Set<EntityReference> = []
            for entityID in entities {
                if let (entity, wasCreated) = entityID.resolve(in: self) {
                    
                    // in theory, resolving the reference to an entity that we want to delete
                    // could actually create it, or other entities referenced by it
                    if wasCreated.count > 0 {
                        added.formUnion(wasCreated.map({ self.makeReference(for: $0) }))
                        datastoreChannel.log("created objects during deletion - probably a mistake: \(added)")
                    }

                    deleted.insert(entityID)
                    context.delete(entity)
                }
            }
            
            self.notify(action: .delete, deleted: deleted)
            completion()
        }
    }
    
    internal func notify(action: EntityChanges.Action, added: Set<EntityReference> = [], deleted: Set<EntityReference> = [], changed: Set<EntityReference> = [], keys: Set<PropertyKey> = []) {
        if notificationsPaused == 0 && ((added.count > 0) || (deleted.count > 0) || (changed.count > 0)) {
            let changes = EntityChanges(action: action, added: added, deleted: deleted, changed: changed, keys: keys)
            let notification = Notification(name: .EntityChangedNotification, object: self, userInfo: ["changes": changes])
            NotificationCenter.default.post(notification)
        }
    }
    
    func suspendNotifications() {
        notificationsPaused += 1
    }
    
    func resumeNotifications() {
        notificationsPaused -= 1
    }
}

// MARK: Conformance Map

extension Datastore {
    
    /// Returns the list of types that another type conforms to.
    /// - Parameter type: the type to look up
    public func conformances(for type: DatastoreType) -> [DatastoreType] {
        return conformanceMap.conformances(for: type)
    }
    
    /// Build the conformance map from the datastore.
    ///
    /// Every EntityRecord in the store has a type. For each unique
    /// value of this, the map contains a mapping to the type `.entity`.
    /// The store can also contain `.typeConformance` records, which
    /// add other entries into the map. This builds up a graph where
    /// types can conform to multiple sub-types, which in turn can conform
    /// to sub-types.
    ///
    /// - Parameter completion: block to run when finished
    func loadConformanceMap(completion: @escaping () -> Void) {
        
        /// Add an entry to the conformance map for the type of every EntityRecord that we find in the database.
        func loadConformanceForEntityRecords(in context: NSManagedObjectContext) {
            let request: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "EntityRecord")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["type"]
            if let entities = try? context.fetch(request), entities.count > 0 {
                let uniqueTypes = Set(entities.map({DatastoreType($0["type"] as! String)}))
                for type in uniqueTypes {
                    if type != .entity {
                        conformanceMap.addConformance(for: type, to: .entity)
                    }
                }
            }
        }
        
        /// Update the conformance map with any conformance records in the database itself.
        func loadConformanceMetadata() {
            let typeMap = self.conformanceMap
            get(allEntitiesOfType: .typeConformance) { entities in
                self.get(properties: [.conformsTo], of: entities) { entities in
                    for entry in entities {
                        if let typeConformance = entry[.conformsTo] as? String {
                            typeMap.addConformance(for: DatastoreType(entry.identifier), to: DatastoreType(typeConformance))
                        }
                    }
        
                    typeMap.expandConformanceRecords()
                    completion()
                }
            }
        }
        
        let context = self.context
        context.perform {
            loadConformanceForEntityRecords(in: context)
            loadConformanceMetadata()
        }
    }
}

// MARK: Caching

extension Datastore {
    func startCaching() {
        entityCache = EntityCache()
    }
    
    func stopCaching() {
        entityCache = nil
    }
    
    func getCached(identifier: String) -> EntityRecord? {
        if let cache = entityCache {
            if let cached = cache.index[identifier] {
                cache.cacheHits += 1
                return cached
            }
            
            cache.cacheMisses += 1
        }
        
        return nil
    }
    
    func addCached(identifier: String, entity: EntityRecord) {
        if let cache = entityCache {
            if let cached = cache.index[identifier] {
                cache.cacheRewrites += 1
                assert(cached === entity)
            } else {
                cache.index[identifier] = entity
            }
        }
    }
}

extension Notification {
    public var entityChanges: EntityChanges? {
        return userInfo?["changes"] as? EntityChanges
    }
}
