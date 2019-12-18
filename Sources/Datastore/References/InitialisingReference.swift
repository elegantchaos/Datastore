// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

protocol EntityInitialiser {
    var initialType: EntityType { get }
    var initialIdentifier: String? { get }
    var initialProperties: PropertyDictionary { get }
}

class InitialisingReference: EntityReference {
    let storedType: EntityType
    let storedIdentifier: String?
    
    override var type: EntityType { return storedType }
    override var identifier: String { return storedIdentifier ?? super.identifier }
    
    required init(_ id: EntityResolver, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        fatalError("typed reference created without type")
    }

    init(_ id: EntityResolver, type: EntityType, initialIdentifier: String? = nil, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        self.storedType = type
        self.storedIdentifier = initialIdentifier
        super.init(id, properties: properties, updates: updates)
    }
}

extension InitialisingReference: EntityInitialiser {
    var initialType: EntityType { return storedType }
    var initialIdentifier: String? { return storedIdentifier }
    var initialProperties: PropertyDictionary { return updates ?? PropertyDictionary() }
}
