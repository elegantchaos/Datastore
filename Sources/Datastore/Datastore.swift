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
    static var cachedModel: NSManagedObjectModel!
    static let model = DatastoreModel()
    
    internal let container: NSPersistentContainer
    internal let context: NSManagedObjectContext
    internal let indexer: NSCoreDataCoreSpotlightDelegate?
    
    public typealias LoadResult = Result<Datastore, Error>
    public typealias SaveResult = Result<Void, Error>
    
    public typealias LoadCompletion = (LoadResult) -> Void
    public typealias SaveCompletion = (SaveResult) -> Void
    public typealias EntitiesCompletion = ([GuaranteedReference]) -> Void
    public typealias EntityCompletion = (GuaranteedReference?) -> Void
    public typealias InterchangeCompletion = ([String:Any]) -> Void
    public typealias CountCompletion = ([Int]) -> Void
    
    struct LoadingModelError: Error { }
    struct InvalidJSONError: Error { }
    
    public typealias ApplyResult = Result<Void, Error>
    
    static let specialProperties: [PropertyKey] = [.identifier, .datestamp, .type]
    
    /// Load a store.
    /// - Parameters:
    ///   - name: name to use for the store
    ///   - url: location of the store; if not supplied, the store will be created in memory
    ///   - container: persistent container class to use
    ///   - indexed: spotlight indexer to use, if required
    ///   - completion: completion block
    public class func load(name: String, url: URL? = nil, container: NSPersistentContainer.Type = NSPersistentContainer.self, indexed: Bool = false, completion: @escaping LoadCompletion) {
        let container = container.init(name: name, managedObjectModel: Datastore.model)
        let description = container.persistentStoreDescriptions[0]
        if let explicitURL = url {
            assert((explicitURL.pathExtension == "sqlite") || (explicitURL.path == "/dev/null"))
            description.url = explicitURL
            try? FileManager.default.createDirectory(at: explicitURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        } else {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
        description.setOption(true as NSValue, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSValue, forKey: NSInferMappingModelAutomaticallyOption)
        description.type = NSSQLiteStoreType
        //        description.setOption(true as NSValue, forKey: NSPersistentHistoryTrackingKey)
        //        description.shouldAddStoreAsynchronously = true
        
        var indexer: NSCoreDataCoreSpotlightDelegate? = nil
        if indexed {
            indexer = NSCoreDataCoreSpotlightDelegate(forStoreWith: description, model: model)
            description.setOption(indexer, forKey:NSCoreDataCoreSpotlightExporter)
        }
        
        container.loadPersistentStores { (description, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let store = Datastore(container: container, indexer: indexer)
                completion(.success(store))
            }
        }
    }
    
    /// Load a store from JSON.
    /// - Parameters:
    ///   - name: name to use for the store
    ///   - json: json string defining the store contents
    ///   - completion: completion block
    public class func load(name: String, json: String, completion: @escaping LoadCompletion) {
        load(name: name) { (result) in
            switch result {
                case .success(let store):
                    store.decode(json: json) { result in
                        completion(result)
                }
                
                default:
                    completion(result)
            }
        }
    }
    
    /// Destroy a store and remove all the backing files
    /// - Parameters:
    ///   - url: location of the store to destroy
    ///   - removeFiles: should be explicitly delete the files?
    public class func destroy(storeAt url: URL, removeFiles: Bool = false) {
        let fm = FileManager.default
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: [:])
            if removeFiles && fm.fileExists(atPath: url.path) {
                try? fm.removeItem(at: url)
            }
        } catch {
            datastoreChannel.log("Failed to destroy store \(url.lastPathComponent).\n\n\(error)")
        }
    }
    
    /// Replace one store with another
    /// - Parameters:
    ///   - url: store to replace
    ///   - destinationURL: store to replace it with
    public class func replace(storeAt url: URL, withStoreAt destinationURL: URL) {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.replacePersistentStore(at: url, destinationOptions: [:], withPersistentStoreFrom: destinationURL, sourceOptions: [:], ofType: NSSQLiteStoreType)
        } catch {
            datastoreChannel.log("Failed to replace store \(url.lastPathComponent).\n\n\(error)")
        }
    }
    
    /// Create a store instance, with a given container and indexer.
    /// - Parameters:
    ///   - container: backing container
    ///   - indexer: spotlight indexer, if required
    private init(container: NSPersistentContainer, indexer: NSCoreDataCoreSpotlightDelegate?) {
        self.container = container
        self.context = container.newBackgroundContext()
        self.indexer = indexer
    }
    
    /// Save any outstanding changes to the store
    /// - Parameter completion: completion block
    public func save(completion: @escaping SaveCompletion) {
        do {
            try context.save()
            completion(.success(Void()))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Reset the store.
    /// Removes all entities.
    /// - Parameter callback: completion block
    open func reset(callback: @escaping LoadCompletion) {
        context.reset()
        context.processPendingChanges()
        callback(.success(self))
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
            var result: [GuaranteedReference] = []
            for entityID in entityIDs {
                if let (entity, wasCreated) = entityID.resolve(in: self) {
                    let reference = GuaranteedReference(entity)
                    result.append(reference)
                    if wasCreated.count > 0 {
                        added.formUnion(wasCreated.map({ GuaranteedReference($0) }))
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
    public func get(entityOfType type: EntityType, where key: PropertyKey, equals: String, createIfMissing: Bool = true, completion: @escaping EntityCompletion) {
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
    public func get(entitiesOfType type: EntityType, where key: PropertyKey, contains: Set<String>, createIfMissing: Bool = true, completion: @escaping EntitiesCompletion) {
        let context = self.context
        
        context.perform {
            var result: [GuaranteedReference] = []
            var create: Set<String> = contains
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
            request.predicate = NSPredicate(format: "type == %@", type.name)
            if let entities = try? context.fetch(request) {
                for entity in entities {
                    if let value = entity.string(withKey: key), contains.contains(value) {
                        result.append(GuaranteedReference(entity))
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
                    let reference = GuaranteedReference(entity)
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
    public func get(allEntitiesOfType type: EntityType, completion: @escaping EntitiesCompletion) {
        let context = self.context
        context.perform {
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
            request.predicate = NSPredicate(format: "type = %@", type.name)
            if let entities = try? context.fetch(request) {
                completion(Array(entities.map({ GuaranteedReference($0) })))
            } else {
                completion([])
            }
        }
    }
    
    /// Count all entities of some entity types.
    /// - Parameters:
    ///   - types: the types to count
    ///   - completion: completion block
    public func count(entitiesOfTypes types: [EntityType], completion: @escaping CountCompletion) {
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
                completion(Array(entities.map({ GuaranteedReference($0) })))
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
                        added.formUnion(wasCreated.map({ GuaranteedReference($0) }))
                    }
                    result.append(GuaranteedReference(entity, properties: values))
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
    public func get(allPropertiesOf entities: [EntityReference], completion: @escaping ([PropertyDictionary]) -> Void) {
        let context = self.context
        context.perform {
            var result: [PropertyDictionary] = []
            var added: Set<EntityReference> = []
            for entityID in entities {
                let values: PropertyDictionary
                if let (entity, wasCreated) = entityID.resolve(in: self) {
                    values = entity.readAllProperties(store: self)
                    if wasCreated.count > 0 {
                        added.formUnion(wasCreated.map({ GuaranteedReference($0) }))
                    }
                } else {
                    values = PropertyDictionary()
                }
                result.append(values)
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
                        added.formUnion(addedByRelationships.map({ GuaranteedReference($0) }))
                    }
                    let reference = GuaranteedReference(entity)
                    
                    if wasCreated.count == 0 {
                        changed.insert(reference)
                        keys.formUnion(values.values.keys)
                    } else {
                        added.formUnion(wasCreated.map({ GuaranteedReference($0) }))
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
                        added.formUnion(addedByRelationships.map({ GuaranteedReference($0) }))
                    }
                    let reference = GuaranteedReference(entity)
                    
                    if wasCreated.count == 0 {
                        changed.insert(reference)
                        keys.formUnion(values.values.keys)
                    } else {
                        added.formUnion(wasCreated.map({ GuaranteedReference($0) }))
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
                        added.formUnion(wasCreated.map({ GuaranteedReference($0) }))
                        datastoreChannel.log("created objects during property removal - probably a mistake: \(added)")
                    }
                    
                    let reference = GuaranteedReference(entity)
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
                        added.formUnion(wasCreated.map({ GuaranteedReference($0) }))
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
        if (added.count > 0) || (deleted.count > 0) || (changed.count > 0) {
            let changes = EntityChanges(action: action, added: added, deleted: deleted, changed: changed, keys: keys)
            let notification = Notification(name: .EntityChangedNotification, object: self, userInfo: ["changes": changes])
            NotificationCenter.default.post(notification)
        }
    }
}

extension Notification {
    public var entityChanges: EntityChanges? {
        return userInfo?["changes"] as? EntityChanges
    }
}
