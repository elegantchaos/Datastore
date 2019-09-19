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
    internal let nullSymbol = SymbolID(named: "null")
    
    public typealias LoadResult = Result<Datastore, Error>
    public typealias LoadCompletion = (LoadResult) -> Void
    public typealias EntitiesCompletion = ([Entity]) -> Void
    public typealias InterchangeCompletion = ([String:Any]) -> Void
    
    struct LoadingModelError: Error { }
    struct InvalidJSONError: Error { }
    
    public typealias ApplyResult = Result<Void, Error>
    
    static let specialProperties = ["name", "uuid", "created", "type", "modified"]
    
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
    
    public func symbol(named name: String) -> SymbolRecord {
        let context = self.context
        let normalizedName = name.lowercased()
        if let symbol = getNamed(normalizedName, type: SymbolRecord.self, in: context, createIfMissing: false) {
            print("found symbol \(normalizedName) \(symbol.uuid!)")
            return symbol
        }
        
        let symbol = SymbolRecord(context: context)
        symbol.name = normalizedName
        print("made symbol \(symbol.name!) \(symbol.uuid!)")
        return symbol
    }
    
    public func symbol(uuid: String, name: String) -> SymbolRecord {
        let context = self.context
        if let symbol = getWithIdentifier(uuid, type: SymbolRecord.self, in: context) {
            print("found symbol \(symbol.name!) \(symbol.uuid!)")
            return symbol
        }
        
        let symbol = SymbolRecord(context: context)
        symbol.name = name.lowercased()
        symbol.uuid = UUID(uuidString: uuid)
        print("made symbol \(symbol.name!) \(symbol.uuid!)")
        return symbol
    }
    
    public func value(_ value: Any?, type: SymbolID? = nil) -> SemanticValue {
        return SemanticValue(value: value, type: type ?? nullSymbol)
    }
    
    public func value(_ value: Any?, type: SymbolRecord?) -> SemanticValue {
        return SemanticValue(value: value, type: type == nil ? nullSymbol : SymbolID(type!))
    }
    
    public func getEntities(ofType typeID: SymbolID, names: Set<String>, createIfMissing: Bool = true, completion: @escaping EntitiesCompletion) {
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
                    if let name = entity.name, names.contains(name) {
                        result.append(entity)
                        create.remove(name)
                    }
                }
            }
            if createIfMissing {
                for name in create {
                    let entity = EntityRecord(context: context)
                    entity.name = name
                    entity.type = type
                    let now = Date()
                    entity.created = now
                    entity.modified = now
                    entity.uuid = UUID()
                    result.append(entity)
                }
            }
            completion(result.map({ Entity($0) }))
        }
    }
    
    public func getAllEntities(ofType type: SymbolID, completion: @escaping EntitiesCompletion) {
        let context = self.context
        context.perform {
            
            if let entities = type.resolve(in: context)?.entities as? Set<EntityRecord> {
                completion(Array(entities.map({ Entity($0) })))
            } else {
                completion([])
            }
        }
    }
    
    public func getProperties(ofEntities entities: [EntityID], withNames names: Set<String>, completion: @escaping ([SemanticDictionary]) -> Void) {
        let context = self.context
        context.perform {
            var result: [SemanticDictionary] = []
            for entityID in entities {
                var values = SemanticDictionary()
                if let entity = entityID.resolve(in: context) {
                    for property in Datastore.specialProperties {
                        if names.contains(property) {
                            values[valueWithKey: property] = self.value(entity.value(forKey: property))
                        }
                    }
                    entity.read(names: names, from: entity.strings, as: StringPropertyRecord.self, into: &values, store: self)
                    entity.read(names: names, from: entity.integers, as: IntegerPropertyRecord.self, into: &values, store: self)
                    entity.read(names: names, from: entity.dates, as: DatePropertyRecord.self, into: &values, store: self)
                    entity.read(names: names, from: entity.relationships, as: RelationshipRecord.self, into: &values, store: self)
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
