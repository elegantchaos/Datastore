// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import CoreData
import Foundation
import UIKit
import Datastore

open class DatastoreDocument: UIManagedDocument {
    public var store: Datastore!
    
    override public var managedObjectModel: NSManagedObjectModel {
        return DatastoreModel.sharedInstance
    }
    
    override public func persistentStoreType(forFileType fileType: String) -> String {
        return Datastore.persistentStoreType
    }
    
    override public func configurePersistentStoreCoordinator(for storeURL: URL, ofType fileType: String, modelConfiguration configuration: String?, storeOptions: [AnyHashable : Any]? = nil) throws {
        var options = Datastore.storeOptions()
        if let storeOptions = storeOptions {
            options.mergeNewOnly(storeOptions)
        }
        try super.configurePersistentStoreCoordinator(for: storeURL, ofType: fileType, modelConfiguration: configuration, storeOptions: options)
    }
    
    override public func open(completionHandler: ((Bool) -> Void)? = nil) {
        super.open() { result in
            if result {
                let store = Datastore(context: self.managedObjectContext)
                self.store = store
            }
            completionHandler?(result)
        }
    }
    
}

public protocol DatastoreSupplierDocument: UIDocument, DatastoreSupplier {
}

extension DatastoreDocument: DatastoreSupplierDocument {
    public var suppliedDatastore: Datastore {
        return store!
    }
}

#endif
