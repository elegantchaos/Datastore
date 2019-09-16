// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import Logger

let datastoreChannel = Channel("com.elegantchaos.datastore")

public class Datastore {
    static var cachedModel: NSManagedObjectModel!
    let container: NSPersistentContainer
    
    public typealias LoadResult = Result<Datastore, Error>
    public typealias LoadCompletion = (LoadResult) -> Void
    
    struct LoadingModelError: Error { }
    struct InvalidJSONError: Error { }
    
    public typealias ApplyResult = Result<Void, Error>
    
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
    
    public func getLabel(_ name: String) -> Label {
        let label = getNamed(name, type: Label.self, in: container.viewContext, createIfMissing: true)!
        return label
    }
    
    public func getEntities(ofType type: Label, names: Set<String>, createIfMissing: Bool, completion: @escaping ([Entity]) -> Void) {
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
    
    public func getEntities(ofType type: String, names: Set<String>, createIfMissing: Bool = true, completion: @escaping ([Entity]) -> Void) {
        getEntities(ofType: getLabel(type), names: names, createIfMissing: createIfMissing, completion: completion)
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
                        property.label = Label.named(key, in: context)
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
        
        let result = LoadResult {
            if let items = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]] {
                for item in items {
                    print(item)
                }
            }
            
            return self
        }
    
        completion(result)
    }
    
    public func interchange(encoder: InterchangeEncoder = NullInterchangeEncoder(), completion: @escaping ([[String:Any]]) -> Void) {
        var result: [[String:Any]] = []
        let context = container.viewContext
        context.perform {
            let request: NSFetchRequest<Entity> = Entity.fetcher(in: context)
            if let results = try? context.fetch(request) {
                for entity in results {
                    var record: [String:Any] = [:]
                    record["name"] = entity.name
                    record["created"] = encoder.encode(date: entity.created)
                    record["modified"] = encoder.encode(date: entity.modified)
                    record["uuid"] = entity.uuid?.uuidString
                    if let properties = entity.strings as? Set<StringProperty> {
                        for property in properties {
                            record[property.label!.name!] = property.value
                        }
                    }
                    result.append(record)
                }
            }
            completion(result)
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
