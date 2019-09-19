// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation


extension DatePropertyRecord: NamedProperty {
    func typedValue(in store: Datastore) -> SemanticValue {
        return store.value(value, type: type)
    }

    func encode(encoder: InterchangeEncoder) -> Any? {
        return encoder.encode(value)
    }
}
