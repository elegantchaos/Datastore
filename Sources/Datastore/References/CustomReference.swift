// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation


open class CustomReference: EntityReference {
    class open func staticType() -> EntityType { return EntityType("unknown-type") }
    
    override public var type: EntityType { return Swift.type(of: self).staticType() }
    
    public required init(_ id: EntityResolver, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        super.init(id, properties: properties, updates: updates)
    }
    
    init(named name: String) {
        let searchers = [MatchByValue(key: .name, value: name)]
        super.init(MatchedID(matchers: searchers))
    }
}

extension CustomReference: EntityInitialiser {
    var initialType: EntityType { return type }
    var initialIdentifier: String? { return nil }
    var initialProperties: PropertyDictionary { return updates ?? PropertyDictionary() }
}
