// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import Logger

let datastoreChannel = Channel("com.elegantchaos.datastore")

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
    
    public class func replace(storeAt url: URL, withStoreAt destinationURL: URL) {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.replacePersistentStore(at: url, destinationOptions: [:], withPersistentStoreFrom: destinationURL, sourceOptions: [:], ofType: NSSQLiteStoreType)
        } catch {
            datastoreChannel.log("Failed to replace store \(url.lastPathComponent).\n\n\(error)")
        }
    }
    
    private init(container: NSPersistentContainer, indexer: NSCoreDataCoreSpotlightDelegate?) {
        self.container = container
        self.context = container.newBackgroundContext()
        self.indexer = indexer
    }
    
    public func save(completion: @escaping SaveCompletion) {
        do {
            try context.save()
            completion(.success(Void()))
        } catch {
            completion(.failure(error))
        }
    }
    
    open func reset(callback: @escaping LoadCompletion) {
        context.reset()
        context.processPendingChanges()
        callback(.success(self))
    }

    public func get(entitiesOfType type: EntityType, withIDs entityIDs: [EntityReference], completion: @escaping EntitiesCompletion) {
        let context = self.context
        context.perform {
            var result: [GuaranteedReference] = []
            for entityID in entityIDs {
                if let entity = entityID.resolve(in: self) {
                    if entity.type == type.name {
                        result.append(GuaranteedReference(entity))
                    }
                }
            }
            completion(result)
        }
    }

    public func get(entityOfType type: EntityType, where key: PropertyKey, equals: String, createIfMissing: Bool = true, completion: @escaping EntityCompletion) {
        get(entitiesOfType: type, where: key, contains: [equals], createIfMissing: createIfMissing) { entities in
            completion(entities.first)
        }
    }
    

    public func get(entitiesOfType type: EntityType, where key: PropertyKey, contains: Set<String>, createIfMissing: Bool = true, completion: @escaping EntitiesCompletion) {
        let context = self.context
        
        context.perform {
            var result: [EntityRecord] = []
            var create: Set<String> = contains
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
            request.predicate = NSPredicate(format: "type == %@", type.name)
            if let entities = try? context.fetch(request) {
                for entity in entities {
                    if let value = entity.string(withKey: key), contains.contains(value) {
                        result.append(entity)
                        create.remove(value)
                    }
                }
            }
            
            if createIfMissing {
                for name in create {
                    let entity = EntityRecord(in: context)
                    entity.type = type.name
                    let property = StringProperty(in: context)
                    property.owner = entity
                    property.name = key.name
                    property.value = name
                    result.append(entity)
                }
            }
            completion(result.map({ GuaranteedReference($0) }))
        }
    }

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

    public func get(properties names: Set<PropertyKey>, of entities: [EntityReference], completion: @escaping ([PropertyDictionary]) -> Void) {
        get(properties: Set(names.map({ $0.name })), of: entities, completion: completion)
    }
    
    public func get(properties names: Set<String>, of entities: [EntityReference], completion: @escaping ([PropertyDictionary]) -> Void) {
        let context = self.context
        context.perform {
            var result: [PropertyDictionary] = []
            for entityID in entities {
                let values: PropertyDictionary
                if let entity = entityID.resolve(in: self) {
                    values = entity.read(properties: names, store: self)
                } else {
                    values = PropertyDictionary()
                }
                result.append(values)
            }
            completion(result)
        }
    }
    
    public func get(allPropertiesOf entities: [EntityReference], completion: @escaping ([PropertyDictionary]) -> Void) {
        let context = self.context
        context.perform {
            var result: [PropertyDictionary] = []
            for entityID in entities {
                let values: PropertyDictionary
                if let entity = entityID.resolve(in: self) {
                    values = entity.readAllProperties(store: self)
                } else {
                    values = PropertyDictionary()
                }
                result.append(values)
            }
            completion(result)
        }
    }
    
    public func add(properties: [EntityReference: PropertyDictionary], completion: @escaping () -> Void) {
        let context = self.context
        context.perform {
            for (entityID, values) in properties {
                if let entity = entityID.resolve(in: self) {
                    values.add(to: entity, store: self)
                }
            }
            completion()
        }
    }
    
    public func update(properties: [EntityReference: PropertyDictionary], completion: @escaping () -> Void) {
        // TODO: implement this properly, so that it only creates new property entries for properties that have actually changed value
        add(properties: properties, completion: completion)
    }
    
    public func remove(properties names: Set<String>, of entities: [EntityReference], completion: @escaping () -> Void) {
        let context = self.context
        context.perform {
            for entityID in entities {
                if let entity = entityID.resolve(in: self) {
                    entity.remove(properties: names, store: self)
                }
            }
            completion()
        }
    }
    
  
}
