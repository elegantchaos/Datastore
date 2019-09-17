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
    let container: NSPersistentContainer
    
    public typealias LoadResult = Result<Datastore, Error>
    public typealias LoadCompletion = (LoadResult) -> Void
    public typealias EntitiesCompletion = ([Entity]) -> Void
    public typealias InterchangeCompletion = ([String:Any]) -> Void
    
    struct LoadingModelError: Error { }
    struct InvalidJSONError: Error { }
    
    public typealias ApplyResult = Result<Void, Error>
    
    struct Publisher: Combine.Publisher {
        typealias Output = Datastore
        typealias Failure = Error
        init(url: URL? = nil) {
            
        }
        func receive<S>(subscriber: S) where S : Subscriber, Error == S.Failure, Datastore == S.Input {
            
        }
        
    }
    
    class func loadCombine(name: String, url: URL? = nil) -> Future<Datastore, Error> {
        let future = Future<Datastore, Error>() { promise in
            load(name: name, url: url) { result in
                promise(result)
            }
        }        
        
        return future
    }
    
    class func load(name: String, url: URL? = nil, completion: @escaping LoadCompletion) {
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
    
    class func load(name: String, json: String, completion: @escaping LoadCompletion) {
        load(name: name) { (result) in
            switch result {
            case .success(let store):
                store.apply(json: json) { result in
                    completion(result)
                }
            
            default:
                completion(result)
            }
        }
    }
    
    private init(container: NSPersistentContainer) {
        self.container = container
    }
    
    public func symbol(named name: String) -> Symbol {
        let context = container.viewContext
        if let symbol = getNamed(name, type: Symbol.self, in: context, createIfMissing: false) {
            print("found symbol \(name) \(symbol.uuid!)")
            return symbol
        }
        
        let symbol = Symbol(context: context)
        symbol.name = name
        symbol.uuid = UUID()
        print("made symbol \(name) \(symbol.uuid!)")
        return symbol
    }

    public func symbol(uuid: String, name: String) -> Symbol {
        let context = container.viewContext
        if let symbol = getWithIdentifier(uuid, type: Symbol.self, in: context) {
            print("found symbol \(symbol.name!) \(symbol.uuid!)")
            return symbol
        }
        
        let symbol = Symbol(context: context)
        symbol.name = name
        symbol.uuid = UUID(uuidString: uuid)
        print("made symbol \(symbol.name!) \(symbol.uuid!)")
        return symbol
    }

    public func getEntities(ofType type: Symbol, names: Set<String>, createIfMissing: Bool, completion: @escaping EntitiesCompletion) {
        let context = container.viewContext
        context.perform {
            var result: [Entity] = []
            var create: Set<String> = names
            if let entities = type.entities as? Set<Entity> {
                for entity in entities {
                    if let name = entity.name, names.contains(name) {
                        result.append(entity)
                        create.remove(name)
                    }
                }
            }
            if createIfMissing {
                for name in create {
                    let entity = Entity(context: context)
                    entity.name = name
                    entity.type = type
                    let now = Date()
                    entity.created = now
                    entity.modified = now
                    entity.uuid = UUID()
                    result.append(entity)
                }
            }
            completion(result)
        }
    }

    public func getEntities(ofType type: String, names: Set<String>, createIfMissing: Bool = true, completion: @escaping EntitiesCompletion) {
        getEntities(ofType: symbol(named: type), names: names, createIfMissing: createIfMissing, completion: completion)
    }

    public func getAllEntities(ofType type: Symbol, completion: @escaping EntitiesCompletion) {
        let context = container.viewContext
        context.perform {
            if let entities = type.entities as? Set<Entity> {
                completion(Array(entities))
            } else {
                completion([])
            }
        }
    }
    
    public func getAllEntities(ofType type: String, completion: @escaping EntitiesCompletion) {
        getAllEntities(ofType: symbol(named: type), completion: completion)
    }
    
    public func getProperties(ofEntities entities: [Entity], withNames names: Set<String>, completion: @escaping ([[String:Any]]) -> Void) {
        let context = container.viewContext
        context.perform {
            var result: [[String:Any]] = []
            for entity in entities {
                var values: [String:Any] = [:]
                if let strings = entity.strings as? Set<StringProperty> {
                    for property in strings {
                        if let name = property.label?.name, names.contains(name) {
                            values[name] = property.value
                        }
                    }
                }
                result.append(values)
            }
            completion(result)
        }
    }
    
    public func add(properties: [Entity: [String:Any]], completion: @escaping () -> Void) {
        let context = container.viewContext
        context.perform {
            for (entity, values) in properties {
                for (key, value) in values {
                    if let string = value as? String {
                        let property = StringProperty(context: context)
                        property.value = string
                        property.label = self.symbol(named: key)
                        property.owner = entity
                    }
                }
            }
            completion()
        }
    }
    
    public func apply(json: String, completion: @escaping (LoadResult) -> Void) {
        guard let data = json.data(using: .utf8) else {
            completion(.failure(InvalidJSONError()))
            return
        }
        
        let context = container.viewContext
        let result = LoadResult {
            var symbolIndex: [String:Symbol] = [:]
            if let items = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                if let symbols = items["symbols"] as? [[String:Any]] {
                    for symbolRecord in symbols {
                        if let uuid = symbolRecord["uuid"] as? String, let name = symbolRecord["name"] as? String {
                            let symbol = self.symbol(uuid: uuid, name: name)
                            symbolIndex[uuid] = symbol
                        }
                    }
                }
                
                if let entities = items["entities"] as? [[String:Any]] {
                    for entityRecord in entities {
                        if let name = entityRecord["name"] as? String, let uuid = entityRecord["uuid"] as? String, let type = entityRecord["type"] as? String {
                            var entity = Entity.withIdentifier(uuid, in: context)
                            if entity == nil {
                                let newEntity = Entity(in: context)
                                newEntity.name = name
                                newEntity.uuid = UUID(uuidString: uuid)
                                newEntity.type = symbolIndex[type]
                                entity = newEntity
                            }
                            if let entity = entity {
                                var entityProperties = entityRecord
                                entityProperties.removeValue(forKey: "name")
                                entityProperties.removeValue(forKey: "uuid")
                                entityProperties.removeValue(forKey: "created")
                                entityProperties.removeValue(forKey: "modified")
                                for (key, value) in entityProperties {
                                    print("read property \(key) \(value)")
                                }
                            }
                        }
                    }
                }
            }
            
            return self
        }
    
        try? context.save()
        completion(result)
    }
    
    public func interchange(encoder: InterchangeEncoder = NullInterchangeEncoder(), completion: @escaping InterchangeCompletion) {
        let context = container.viewContext
        context.perform {
            var symbolResults: [[String:Any]] = []
            var entityResults: [[String:Any]] = []
            let request: NSFetchRequest<Symbol> = Symbol.fetcher(in: context)
            if let symbols = try? context.fetch(request) {
                for symbol in symbols {
                    var record: [String:Any] = [:]
                    let type = encoder.encode(uuid: symbol.uuid)
                    record["name"] = symbol.name
                    record["uuid"] = type
                    symbolResults.append(record)
                    
                    if let entities = symbol.entities as? Set<Entity> {
                        for entity in entities {
                            var record: [String:Any] = [:]
                            record["name"] = entity.name
                            record["type"] = type
                            record["created"] = encoder.encode(date: entity.created)
                            record["modified"] = encoder.encode(date: entity.modified)
                            record["uuid"] = entity.uuid!.uuidString
                            if let properties = entity.strings as? Set<StringProperty> {
                                for property in properties {
                                    record[property.label!.name!] = property.value
                                }
                            }
                            entityResults.append(record)
                        }
                    }
                }
                let result = [
                    "symbols" : symbolResults,
                    "entities" : entityResults
                ]
                completion(result)
            }
        }
    }
    
    public func interchangeJSON(completion: @escaping (String) -> Void) {
        interchange(encoder: JSONInterchangeEncoder()) { dictionary in
            if let data = try? JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted]), let json = String(data: data, encoding: .utf8) {
                completion(json)
            } else {
                completion("[]")
            }
        }
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
