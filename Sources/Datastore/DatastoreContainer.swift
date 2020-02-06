// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


import CoreData
import Foundation

protocol ContainerWithStore: NSPersistentContainer {
    var store: Datastore { get set }
}

class SimpleContainerWithStore: NSPersistentContainer, ContainerWithStore {
    var _store: Datastore!
    var store: Datastore {
        get { return _store }
        set { _store = newValue }
    }
}

class DatastoreContainer {
    public typealias LoadResult = Result<ContainerWithStore, Error>
    public typealias LoadCompletion = (LoadResult) -> Void

     /// Load a store.
     /// - Parameters:
     ///   - name: name to use for the store
     ///   - url: location of the store; if not supplied, the store will be created in memory
     ///   - container: persistent container class to use
     ///   - indexed: spotlight indexer to use, if required
     ///   - completion: completion block
    public class func load(name: String, url: URL? = nil, container: ContainerWithStore.Type = SimpleContainerWithStore.self, indexed: Bool = false, completion: @escaping LoadCompletion) {
        
        let container = container.init(name: name, managedObjectModel: DatastoreModel.sharedInstance)
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
            indexer = NSCoreDataCoreSpotlightDelegate(forStoreWith: description, model: DatastoreModel.sharedInstance)
             description.setOption(indexer, forKey:NSCoreDataCoreSpotlightExporter)
         }
         
         container.loadPersistentStores { (description, error) in
             if let error = error {
                 completion(.failure(error))
             } else {
                let context = container.newBackgroundContext()
                let store = Datastore(context: context, indexer: indexer)
                 if url != nil {
                     store.loadConformanceMap() {
                        container.store = store
                        completion(.success(container))
                     }
                 } else {
                     container.store = store
                     completion(.success(container))
                 }
             }
         }
     }
     
     /// Load a store from JSON.
     /// - Parameters:
     ///   - name: name to use for the store
     ///   - json: json string defining the store contents
     ///   - completion: completion block
     public class func load(name: String, json: String, completion: @escaping LoadCompletion) {
         load(name: name) { (result) in
             switch result {
                 case .success(let container):
                    let store = container.store
                    store.decode(json: json) { result in
                        switch result {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success():
                                store.loadConformanceMap {
                                    completion(.success(container))
                                }
                        }
                 }
                 
                 default:
                     completion(result)
             }
         }
     }
    
    /// Destroy a store and remove all the backing files
    /// - Parameters:
    ///   - url: location of the store to destroy
    ///   - removeFiles: should be explicitly delete the files?
    public class func destroy(storeAt url: URL, removeFiles: Bool = false) {
        let fm = FileManager.default
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: DatastoreModel.sharedInstance)
        do {
            try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: [:])
            if removeFiles && fm.fileExists(atPath: url.path) {
                try? fm.removeItem(at: url)
            }
        } catch {
            datastoreChannel.log("Failed to destroy store \(url.lastPathComponent).\n\n\(error)")
        }
    }
    
    /// Replace one store with another
    /// - Parameters:
    ///   - url: store to replace
    ///   - destinationURL: store to replace it with
    public class func replace(storeAt url: URL, withStoreAt destinationURL: URL) {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: DatastoreModel.sharedInstance)
        do {
            try coordinator.replacePersistentStore(at: url, destinationOptions: [:], withPersistentStoreFrom: destinationURL, sourceOptions: [:], ofType: NSSQLiteStoreType)
        } catch {
            datastoreChannel.log("Failed to replace store \(url.lastPathComponent).\n\n\(error)")
        }
    }

}
