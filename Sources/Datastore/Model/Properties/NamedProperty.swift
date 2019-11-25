// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

public class NamedProperty: NSManagedObject {
    @NSManaged public var datestamp: Date?
    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var owner: EntityRecord?
    
    var semanticValue: SemanticValue {
        return SemanticValue(nil)
    }
    
    func encode(with encoder: InterchangeEncoder, into record: inout [String:Any]) {
        
    }

    func encode(with encoder: InterchangeEncoder) -> Any? {
        var value: [String:Any] = [:]
        encode(with: encoder, into: &value)
        return value
    }
}
