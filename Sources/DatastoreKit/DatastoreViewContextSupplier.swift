// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2019.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import UIKit
import Datastore

public protocol DatastoreSupplier {
    var suppliedDatastore: Datastore { get }
}

extension UIViewController {
    func findStore() -> Datastore? {
        if let supplier = self as? DatastoreSupplier {
            return supplier.suppliedDatastore
        } else {
            return parent?.findStore()
        }
    }
}
#endif
