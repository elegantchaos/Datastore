// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if targetEnvironment(macCatalyst) || !os(macOS)
import UIKit
import Datastore

class RelationshipPropertyView: UILabel, DatastorePropertyView {
    func setup(value: PropertyValue, withKey: PropertyKey, label: UILabel, for controller: DatastorePropertyController) {
        if let reference = value.value as? EntityReference {
            text = ""
            label.text = value.type?.name
            controller.store.get(properties: ["name"], of: [reference]) { results in
                DispatchQueue.main.async {
                    if let entity = results.first {
                        self.text = entity["name"] as? String
                    }
                }
            }

        }
    }
}
#endif

