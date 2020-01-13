// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2019.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import Datastore

public protocol DatastoreViewContextSupplier {
    var viewDatastore: Datastore { get }
}

extension UIViewController {
    func findStore() -> Datastore? {
        if let supplier = self as? DatastoreViewContextSupplier {
            return supplier.viewDatastore
        } else {
            return parent?.findStore()
        }
    }
}
