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

    struct LocatingModelError: Error {
    }
    
    struct LoadingModelError: Error {
        
    }

    class func load(name: String, url: URL? = nil, completion: @escaping (LoadResult) -> Void) {
        let model = Datastore.model()
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
        return Label()
    }
    
    public func getEntity(named name: Label, kind: Label) -> Entity {
        return Entity()
    }
    
    public func getEntity(named name: String, kind: String) -> Entity {
        return getEntity(named: getLabel(name), kind: getLabel(kind))
    }
    
    public class func modelURL(bundle: Bundle = Bundle(for: Datastore.self)) -> URL {
        guard let url = bundle.url(forResource: "Model", withExtension: "momd") else {
            datastoreChannel.fatal(LocatingModelError())
        }
        
        return url
    }

    public class func model(bundle: Bundle = Bundle(for: Datastore.self), cached: Bool = true) -> NSManagedObjectModel {
        if cached && (cachedModel != nil) {
            return cachedModel
        }

        let url = Datastore.modelURL(bundle: bundle)
        guard let model = NSManagedObjectModel(contentsOf: url) else {
            datastoreChannel.fatal(LoadingModelError())
        }

        datastoreChannel.debug("loaded collection model")
        if (cached) {
            cachedModel = model
        }

        return model
    }
}
