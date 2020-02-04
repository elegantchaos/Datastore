// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

protocol EntityInitialiser {
    var initialType: DatastoreType { get }
    var initialProperties: PropertyDictionary { get }
}

class InitialisingReference: EntityReference {
    let storedType: DatastoreType
    
    override var type: DatastoreType { return storedType }
    override var identifier: String { return (updates?[.identifier] as? String) ?? super.identifier }
    
    required init(_ id: EntityResolver, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        fatalError("typed reference created without type")
    }

    init(_ id: EntityResolver, type: DatastoreType, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        self.storedType = type
        super.init(id, properties: properties, updates: updates)
    }
}

extension InitialisingReference: EntityInitialiser {
    var initialType: DatastoreType { return storedType }
    var initialProperties: PropertyDictionary { return updates ?? PropertyDictionary() }
}
