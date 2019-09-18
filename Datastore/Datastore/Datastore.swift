// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import Logger
import Combine

let datastoreChannel = Channel("com.elegantchaos.datastore")

public protocol ResolvableID {
    func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID
    var object: NSManagedObject? { get }
}

public struct NullCachedID: ResolvableID {
    public func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID {
        return self
    }
    
    public var object: NSManagedObject? {
        return nil
    }
}

public struct OpaqueCachedID: ResolvableID {
    let cached: NSManagedObject
    let id: NSManagedObjectID
    
    public init(_ object: NSManagedObject) {
        self.cached = object
        self.id = object.objectID
    }
    
    public func resolve(in context: NSManagedObjectContext, as objectType: NSManagedObject.Type) -> ResolvableID {
        if context == cached.managedObjectContext {
            if type(of: cached) == objectType {
                return self
            } else {
                return NullCachedID()
            }
        } else {
            let object = context.object(with: id)
            return OpaqueCachedID(object)
        }
    }
    
    public var object: NSManagedObject? {
        return cached
    }
}

public struct OpaqueNamedID: ResolvableID {
    let name: String
    let createIfMissing: Bool
    
    public func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID {
        if let object = type.named(name, in: context, createIfMissing: createIfMissing) {
            return OpaqueCachedID(object)
        } else {
            return NullCachedID()
        }
    }
    
    public var object: NSManagedObject? {
        fatalError("identifier unresolved")
        return nil
    }
}

public struct OpaqueIdentifiedID: ResolvableID {
    let uuid: String
    
    public func resolve(in context: NSManagedObjectContext, as type: NSManagedObject.Type) -> ResolvableID {
        if let object = type.withIdentifier(uuid, in: context) {
            return OpaqueCachedID(object)
        } else {
            return NullCachedID()
        }
    }
    
    public var object: NSManagedObject? {
        fatalError("identifier unresolved")
        return nil
    }
}

public struct WrappedID<T: NSManagedObject> {
    let id: ResolvableID
    
    init(_ object: T) {
        self.id = OpaqueCachedID(object)
    }
    
    init(_ id: ResolvableID) {
        self.id = id
    }
    
    init(named name: String, createIfMissing: Bool) {
        self.id = OpaqueNamedID(name: name, createIfMissing: createIfMissing)
    }
    
    init(uuid: String) {
        self.id = OpaqueIdentifiedID(uuid: uuid)
    }
    
    public func resolve(in context: NSManagedObjectContext) -> WrappedID {
        let resolved = id.resolve(in: context, as: T.self)
        return WrappedID(resolved)
    }
    
    var object: T? {
        return id.object as? T
    }
}

public struct GuaranteedWrappedID<T: NSManagedObject> {
    let id: ResolvableID
    
    init(_ object: T) {
        self.id = OpaqueCachedID(object)
    }
    
    init(_ id: ResolvableID) {
        self.id = id
    }
    
    init(named name: String, createIfMissing: Bool) {
        self.id = OpaqueNamedID(name: name, createIfMissing: createIfMissing)
    }
    
    init(uuid: String) {
        self.id = OpaqueIdentifiedID(uuid: uuid)
    }
    
    public func resolve(in context: NSManagedObjectContext) -> GuaranteedWrappedID {
        let resolved = id.resolve(in: context, as: T.self)
        return GuaranteedWrappedID(resolved)
    }
    
    var object: T {
        return id.object as! T
    }
}


public typealias EntityID = WrappedID<Entity>
public typealias SymbolID = WrappedID<Symbol>

public typealias GuaranteedEntityID = GuaranteedWrappedID<Entity>
public typealias GuaranteedSymbolID = GuaranteedWrappedID<Symbol>


public class Datastore {
    static var cachedModel: NSManagedObjectModel!
    let container: NSPersistentContainer
    
    public typealias LoadResult = Result<Datastore, Error>
    public typealias LoadCompletion = (LoadResult) -> Void
    public typealias EntitiesCompletion = ([GuaranteedEntityID]) -> Void
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
    
    public func getEntities(ofType typeID: SymbolID, names: Set<String>, createIfMissing: Bool, completion: @escaping EntitiesCompletion) {
        let context = container.viewContext
        context.perform {
            var result: [Entity] = []
            var create: Set<String> = names
            guard let type = typeID.resolve(in: context).object else {
                completion([])
                return
            }
            
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
            completion(result.map({ GuaranteedEntityID($0) }))
        }
    }
    
    public func getEntities(ofType type: String, names: Set<String>, createIfMissing: Bool = true, completion: @escaping EntitiesCompletion) {
        getEntities(ofType: SymbolID(named: type, createIfMissing: true), names: names, createIfMissing: createIfMissing, completion: completion)
    }
    
    public func getAllEntities(ofType type: Symbol, completion: @escaping EntitiesCompletion) {
        let context = container.viewContext
        context.perform {
            if let entities = type.entities as? Set<Entity> {
                completion(Array(entities.map({ GuaranteedEntityID($0) })))
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
                        if let name = property.name?.name, names.contains(name) {
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
                    entity.add(property: self.symbol(named: key), value: value)
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
