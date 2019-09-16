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
    
    typealias LoadResult = Result<Datastore, Error>

    struct LoadingModelError: Error {
        
    }

    class func load(name: String, url: URL? = nil, completion: @escaping (LoadResult) -> Void) {
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
    
    public func interchange(completion: @escaping ([[String:Any]]) -> Void) {
        var result: [[String:Any]] = []
        let context = container.viewContext
        context.perform {
            let request: NSFetchRequest<Entity> = Entity.fetcher(in: context)
            if let results = try? context.fetch(request) {
                for entity in results {
                    var record: [String:Any] = [:]
                    record["name"] = entity.name
                    record["created"] = entity.created
                    record["modified"] = entity.modified
                    record["uuid"] = entity.uuid?.uuidString
                    result.append(record)
                }
            }
            completion(result)
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
