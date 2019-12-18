// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public class RelationshipProperty: NamedProperty {
    @NSManaged public var target: EntityRecord

    override func propertyValue(for store: Datastore) -> PropertyValue {
        return PropertyValue(store.makeReference(for: target), type: type, datestamp: datestamp)
    }
    
    override func encode(with encoder: InterchangeEncoder, into record: inout [String:Any]) {
        encoder.encode(self, into: &record)
    }
    
    public override func awakeFromInsert() {
        datestamp = Date()
    }

}
