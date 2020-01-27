// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import UIKit
import Datastore

class IntegerPropertyView: UILabel, DatastorePropertyView {
    func setup(value: PropertyValue, withKey: PropertyKey, for controller: DatastorePropertyController) {
        let coerced: Int = value.coerced(or: 0)
        text = "\(coerced) (int)"
    }
}
#endif

