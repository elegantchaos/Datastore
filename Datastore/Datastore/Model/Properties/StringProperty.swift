// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension StringProperty: NamedProperty {
    func typedValue(in store: Datastore) -> SemanticValue {
        return store.value(value, type: type, datestamp: datestamp)
    }
    
    func encode(with encoder: InterchangeEncoder, into record: inout [String:Any]) {
        encoder.encode(self, into: &record)
    }
    
    public override func awakeFromInsert() {
        datestamp = Date()
    }
}
