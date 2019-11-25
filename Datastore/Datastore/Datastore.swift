// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import Logger
import Combine

let datastoreChannel = Channel("com.elegantchaos.datastore")


public class Datastore {
    static var cachedModel: NSManagedObjectModel!
    static let standardNames = StandardNames()
    
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
    
    static let specialProperties = [Datastore.standardNames.uuid, Datastore.standardNames.datestamp, Datastore.standardNames.type]
    
    public class func loadCombine(name: String, url: URL? = nil) -> Future<Datastore, Error> {
        let future = Future<Datastore, Error>() { promise in
            load(name: name, url: url) { result in
                promise(result)
            }
        }        
        
        return future
    }
    
    public class func load(name: String, url: URL? = nil, container: NSPersistentContainer.Type = NSPersistentContainer.self, completion: @escaping LoadCompletion) {
//        guard let model = Datastore.model() else {
//            completion(.failure(LoadingModelError()))
//            return
//        }
        
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
    
    public func get(entitiesOfType type: String, where key: String, contains: Set<String>, createIfMissing: Bool = true, completion: @escaping EntitiesCompletion) {
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
                    entity.type = type
                    let property = StringProperty(in: context)
                    property.owner = entity
                    property.name = key
                    property.value = name
                    result.append(entity)
                }
            }
            completion(result.map({ Entity($0) }))
        }
    }
    
    public func get(entityOfType type: String, where key: String, equals: String, createIfMissing: Bool = true, completion: @escaping EntityCompletion) {
        get(entitiesOfType: type, where: key, contains: [equals], createIfMissing: createIfMissing) { entities in
            completion(entities.first)
        }
    }
    
    public func get(allEntitiesOfType type: String, completion: @escaping EntitiesCompletion) {
        let context = self.context
        context.perform {
            
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context)
            request.predicate = NSPredicate(format: "type = %@", type)
            if let entities = try? context.fetch(request) {
                completion(Array(entities.map({ Entity($0) })))
            } else {
                completion([])
            }
        }
    }
    
    public func get(properties names: Set<String>, of entities: [EntityID], completion: @escaping ([SemanticDictionary]) -> Void) {
        let context = self.context
        context.perform {
            var result: [SemanticDictionary] = []
            for entityID in entities {
                let values: SemanticDictionary
                if let entity = entityID.resolve(in: context) {
                    values = entity.read(properties: names, store: self)
                } else {
                    values = SemanticDictionary()
                }
                result.append(values)
            }
            completion(result)
        }
    }
    
    public func get(allPropertiesOf entities: [EntityID], completion: @escaping ([SemanticDictionary]) -> Void) {
        let context = self.context
        context.perform {
            var result: [SemanticDictionary] = []
            for entityID in entities {
                let values: SemanticDictionary
                if let entity = entityID.resolve(in: context) {
                    values = entity.readAllProperties(store: self)
                } else {
                    values = SemanticDictionary()
                }
                result.append(values)
            }
            completion(result)
        }
    }
    
    public func add(properties: [EntityID: SemanticDictionary], completion: @escaping () -> Void) {
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
    
    public func update(properties: [EntityID: SemanticDictionary], completion: @escaping () -> Void) {
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
    
    public static var model: NSManagedObjectModel = makeModel()
//    {
//        if cached && (cachedModel != nil) {
//            return cachedModel
//        }
//
//        let loadModel = false
//
//        if loadModel {
//                    guard let url = bundle.url(forResource: "Model", withExtension: "momd") else {
//                        datastoreChannel.debug("failed to locate model")
//                        return nil
//                    }
//
//                    guard let model = NSManagedObjectModel(contentsOf: url) else {
//                        datastoreChannel.debug("failed to load model")
//                        return nil
//                    }
//
//                    datastoreChannel.debug("loaded collection model")
//                    if (cached) {
//                        cachedModel = model
//                    }
//
//                    return model
//        } else {
//            cachedModel = makeModel()
//            return cachedModel
//        }
//    }
    
    private class func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entityRecord = NSEntityDescription()
        entityRecord.name = "EntityRecord"
        let datestamp = NSAttributeDescription()
        datestamp.name = "datestamp"
        datestamp.attributeType = .dateAttributeType
        let type = NSAttributeDescription()
        type.name = "type"
        type.attributeType = .stringAttributeType
        let uuid = NSAttributeDescription()
        uuid.name = "uuid"
        uuid.attributeType = .UUIDAttributeType
        entityRecord.properties = [datestamp, type, uuid]

        model.entities = [
            entityRecord,
            makeEntity("Data", type: .binaryDataAttributeType, ownerEntity: entityRecord),
            makeEntity("Date", type: .dateAttributeType, ownerEntity: entityRecord),
            makeEntity("Double", type: .doubleAttributeType, ownerEntity: entityRecord),
            makeEntity("Integer", type: .integer64AttributeType, ownerEntity: entityRecord),
            makeRelationshipEntity(ownerEntity: entityRecord),
            makeEntity("String", type: .stringAttributeType, ownerEntity: entityRecord)
        ]
        
        return model
    }
    
    private class func makeEntity(_ entityName: String, type attributeType: NSAttributeType?, ownerEntity: NSEntityDescription) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name =  entityName + "Property"
        let datestamp = NSAttributeDescription()
        datestamp.name = "datestamp"
        datestamp.attributeType = .dateAttributeType
        let name = NSAttributeDescription()
        name.name = "name"
        name.attributeType = .stringAttributeType
        let type = NSAttributeDescription()
        type.name = "type"
        type.attributeType = .stringAttributeType
        let owner = NSRelationshipDescription()
        owner.name = "owner"
        owner.destinationEntity = ownerEntity
        owner.deleteRule = .nullifyDeleteRule
        owner.maxCount = 1
        let ownerInverse = NSRelationshipDescription()
        ownerInverse.name = entityName.lowercased() + "s"
        ownerInverse.destinationEntity = entity
        owner.inverseRelationship = ownerInverse
        ownerInverse.inverseRelationship = owner
        ownerEntity.properties.append(ownerInverse)
        entity.properties = [datestamp, name, type, owner]

        if let attributeType = attributeType {
            let value = NSAttributeDescription()
            value.name = "value"
            value.attributeType = attributeType
            entity.properties.append(value)
        }

        return entity
    }
    
    private class func makeRelationshipEntity(ownerEntity: NSEntityDescription) -> NSEntityDescription {
        let relationship = makeEntity("Relationship", type: .binaryDataAttributeType, ownerEntity: ownerEntity)

        let target = NSRelationshipDescription()
        target.name = "target"
        target.destinationEntity = ownerEntity
        target.deleteRule = .nullifyDeleteRule
        target.maxCount = 1
        let targetInverse = NSRelationshipDescription()
        targetInverse.name = "targets"
        targetInverse.destinationEntity = ownerEntity
        target.inverseRelationship = targetInverse
        targetInverse.inverseRelationship = target
        ownerEntity.properties.append(targetInverse)

        return relationship
    }
}
