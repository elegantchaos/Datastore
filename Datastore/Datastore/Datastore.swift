// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import Logger
import Combine

let datastoreChannel = Channel("com.elegantchaos.datastore")


public class Datastore {
    static var cachedModel: NSManagedObjectModel!
    internal let container: NSPersistentContainer
    internal let context: NSManagedObjectContext
    internal let valueSymbol = SymbolID(named: "value")
    internal let stringSymbol = SymbolID(named: "string")
    internal let numberSymbol = SymbolID(named: "number")
    internal let dateSymbol = SymbolID(named: "date")
    internal let entitySymbol = SymbolID(named: "entity")
    internal let nameSymbol = SymbolID(named: "name")
    
    public typealias LoadResult = Result<Datastore, Error>
    public typealias LoadCompletion = (LoadResult) -> Void
    public typealias EntitiesCompletion = ([Entity]) -> Void
    public typealias InterchangeCompletion = ([String:Any]) -> Void
    
    struct LoadingModelError: Error { }
    struct InvalidJSONError: Error { }
    
    public typealias ApplyResult = Result<Void, Error>
    
    static let specialProperties = ["uuid", "datestamp", "type"]
    
    struct Publisher: Combine.Publisher {
        typealias Output = Datastore
        typealias Failure = Error
        init(url: URL? = nil) {
            
        }
        func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, Datastore == S.Input {
            
        }
        
    }
    
    public class func loadCombine(name: String, url: URL? = nil) -> Future<Datastore, Error> {
        let future = Future<Datastore, Error>() { promise in
            load(name: name, url: url) { result in
                promise(result)
            }
        }        
        
        return future
    }
    
    public class func load(name: String, url: URL? = nil, completion: @escaping LoadCompletion) {
        guard let model = Datastore.model() else {
            completion(.failure(LoadingModelError()))
            return
        }
        
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        let description = container.persistentStoreDescriptions[0]
        description.setOption(true as NSValue, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSValue, forKey: NSInferMappingModelAutomaticallyOption)
        description.type = NSSQLiteStoreType
        
        if let explicitURL = url {
            assert((explicitURL.pathExtension == "sqlite") || (explicitURL.path == "/dev/null"))
            description.url = explicitURL
        } else {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
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
    
    public func value(_ value: Any?, type: SymbolID? = nil) -> SemanticValue {
        return SemanticValue(value: value, type: type ?? valueSymbol)
    }
    
    public func value(_ value: Any?, type: SymbolRecord?) -> SemanticValue {
        return SemanticValue(value: value, type: type == nil ? valueSymbol : SymbolID(type!))
    }
    
    public func get(entities names: Set<String>, ofType typeID: SymbolID, createIfMissing: Bool = true, completion: @escaping EntitiesCompletion) {
        let context = self.context
        
        context.perform {
            var result: [EntityRecord] = []
            var create: Set<String> = names
            guard let type = typeID.resolve(in: context) else {
                completion([])
                return
            }
            
            if let entities = type.entities as? Set<EntityRecord> {
                for entity in entities {
                    if let name = entity.string(withKey: self.nameSymbol), names.contains(name) {
                        result.append(entity)
                        create.remove(name)
                    }
                }
            }
            
            let nameKey = self.nameSymbol.resolve(in: context)
            if createIfMissing {
                for name in create {
                    let entity = EntityRecord(in: context)
                    entity.type = type
                    let property = StringProperty(in: context)
                    property.owner = entity
                    property.name = nameKey
                    property.value = name
                    result.append(entity)
                }
            }
            completion(result.map({ Entity($0) }))
        }
    }
    
    public func get(allEntitiesOfType type: SymbolID, completion: @escaping EntitiesCompletion) {
        let context = self.context
        context.perform {
            
            if let entities = type.resolve(in: context)?.entities as? Set<EntityRecord> {
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
    
    public func remove(properties names: Set<String>, completion: @escaping () -> Void) {
    }
    
    public class func model(bundle: Bundle = Bundle(for: Datastore.self), cached: Bool = true) -> NSManagedObjectModel? {
        if cached && (cachedModel != nil) {
            return cachedModel
        }
        
        guard let url = bundle.url(forResource: "Model", withExtension: "momd") else {
            datastoreChannel.debug("failed to locate model")
            return nil
        }
        
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            datastoreChannel.debug("failed to load model")
            return nil
        }
        
        datastoreChannel.debug("loaded collection model")
        if (cached) {
            cachedModel = model
        }
        
        return model
    }
}
