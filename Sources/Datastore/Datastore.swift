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
    
    public typealias LoadResult = Result<Datastore, Error>
    public typealias SaveResult = Result<Void, Error>
    
    public typealias LoadCompletion = (LoadResult) -> Void
    public typealias SaveCompletion = (SaveResult) -> Void
    public typealias EntitiesCompletion = ([Entity]) -> Void
    public typealias EntityCompletion = (Entity?) -> Void
    public typealias InterchangeCompletion = ([String:Any]) -> Void
    
    struct LoadingModelError: Error { }
    struct InvalidJSONError: Error { }
    
    public typealias ApplyResult = Result<Void, Error>
    
    static let specialProperties: [PropertyKey] = [.identifier, .datestamp, .type]
    
    public class func load(name: String, url: URL? = nil, container: NSPersistentContainer.Type = NSPersistentContainer.self, completion: @escaping LoadCompletion) {
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
        
        
        container.loadPersistentStores { (description, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let store = Datastore(container: container)
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
    
    private init(container: NSPersistentContainer) {
        self.container = container
        self.context = container.newBackgroundContext()
    }
    
    public func save(completion: @escaping SaveCompletion) {
        do {
            try context.save()
            completion(.success(Void()))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func get(entitiesOfType type: EntityType, where key: PropertyKey, contains: Set<String>, createIfMissing: Bool = true, completion: @escaping EntitiesCompletion) {
        let context = self.context
        
        context.perform {
            var result: [EntityRecord] = []
            var create: Set<String> = contains
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
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
            completion(result.map({ Entity($0) }))
        }
    }
    
    public func get(entitiesOfType type: EntityType, withIDs entityIDs: [EntityID], completion: @escaping EntitiesCompletion) {
        let context = self.context
        context.perform {
            var result: [Entity] = []
            for entityID in entityIDs {
                if let entity = entityID.resolve(in: context, as: type) {
                    result.append(Entity(entity))
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
    
    public func get(allEntitiesOfType type: EntityType, completion: @escaping EntitiesCompletion) {
        let context = self.context
        context.perform {
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
            request.predicate = NSPredicate(format: "type = %@", type.name)
            if let entities = try? context.fetch(request) {
                completion(Array(entities.map({ Entity($0) })))
            } else {
                completion([])
            }
        }
    }
    
    public func get(properties names: Set<String>, of entities: [EntityID], completion: @escaping ([PropertyDictionary]) -> Void) {
        let context = self.context
        context.perform {
            var result: [PropertyDictionary] = []
            for entityID in entities {
                let values: PropertyDictionary
                if let entity = entityID.resolve(in: context) {
                    values = entity.read(properties: names, store: self)
                } else {
                    values = PropertyDictionary()
                }
                result.append(values)
            }
            completion(result)
        }
    }
    
    public func get(allPropertiesOf entities: [EntityID], completion: @escaping ([PropertyDictionary]) -> Void) {
        let context = self.context
        context.perform {
            var result: [PropertyDictionary] = []
            for entityID in entities {
                let values: PropertyDictionary
                if let entity = entityID.resolve(in: context) {
                    values = entity.readAllProperties(store: self)
                } else {
                    values = PropertyDictionary()
                }
                result.append(values)
            }
            completion(result)
        }
    }
    
    public func add(properties: [EntityID: PropertyDictionary], completion: @escaping () -> Void) {
        let context = self.context
        context.perform {
            for (entityID, values) in properties {
                if let entity = entityID.resolve(in: context) {
                    values.add(to: entity, store: self)
                }
            }
            completion()
        }
    }
    
    public func update(properties: [EntityID: PropertyDictionary], completion: @escaping () -> Void) {
    }
    
    public func remove(properties names: Set<String>, of entities: [EntityID], completion: @escaping () -> Void) {
        let context = self.context
        context.perform {
            for entityID in entities {
                if let entity = entityID.resolve(in: context) {
                    entity.remove(properties: names, store: self)
                }
            }
            completion()
        }
    }
    
  
}
