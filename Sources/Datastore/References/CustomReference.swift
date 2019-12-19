// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation


open class CustomReference: EntityReference {
    class open func staticType() -> EntityType { return .unknown }
    
    override public var type: EntityType { return Swift.type(of: self).staticType() }
    
    public required init(_ id: EntityResolver, properties: PropertyDictionary? = nil, updates: PropertyDictionary? = nil) {
        super.init(id, properties: properties, updates: updates)
    }
    
    init(with properties: PropertyDictionary? = nil) {
        super.init(MatchingResolver(matchers: []), updates: properties)
    }
    
    init(named name: String, with properties: PropertyDictionary? = nil) {
        let matchers = [MatchByValue(key: .name, value: name)]
        super.init(MatchingResolver(matchers: matchers), updates: properties)
    }
    
    init(identifiedBy identifier: String, with properties: PropertyDictionary?) {
        let matchers = [MatchByIdentifier(identifier: identifier)]
        super.init(MatchingResolver(matchers: matchers), updates: properties)
    }
}

extension CustomReference: EntityInitialiser {
    var initialType: EntityType { return type }
    var initialIdentifier: String? { return nil }
    var initialProperties: PropertyDictionary { return updates ?? PropertyDictionary() }
}
