// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import CoreData
import Foundation
import UIKit

class DatastoreDocument: UIManagedDocument {
    var store: Datastore!
    
    override var managedObjectModel: NSManagedObjectModel {
        return DatastoreModel.sharedInstance
    }
    
    override func persistentStoreType(forFileType fileType: String) -> String {
        return Datastore.persistentStoreType
    }
    
    override func configurePersistentStoreCoordinator(for storeURL: URL, ofType fileType: String, modelConfiguration configuration: String?, storeOptions: [AnyHashable : Any]? = nil) throws {
        let options = Datastore.storeOptions()
        persistentStoreOptions?.mergeReplacingDuplicates(options)
        try super.configurePersistentStoreCoordinator(for: storeURL, ofType: fileType, modelConfiguration: configuration, storeOptions: storeOptions)
    }
    
    override func open(completionHandler: ((Bool) -> Void)? = nil) {
        super.open() { result in
            if result {
                let store = Datastore(context: self.managedObjectContext, indexer: nil)
                self.store = store
            }
            completionHandler?(result)
        }
    }
}
#endif
