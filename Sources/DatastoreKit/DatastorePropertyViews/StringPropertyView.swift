// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import UIKit
import Datastore

class StringPropertyView: UILabel, DatastorePropertyView {
    func setup(value: PropertyValue, withKey: PropertyKey, for controller: DatastorePropertyController) {
        let string = value.coerced(or: "")
        text = "\(string) (string)"
    }
}
#endif
