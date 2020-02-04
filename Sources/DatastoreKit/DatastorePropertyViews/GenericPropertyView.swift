// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import UIKit
import Datastore

class GenericPropertyView: UILabel, DatastorePropertyView {
    func setup(value: PropertyValue, withKey: PropertyKey, label: UILabel, for controller: DatastorePropertyController) {
        if let actualValue = value.value {
            let typeConformance = value.type?.name ?? "<unknown type>"
            text = "\(actualValue) (\(typeConformance))"
        } else {
            text = "<nil>"
        }
    }
}
#endif
