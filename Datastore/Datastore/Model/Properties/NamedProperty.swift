// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

protocol NamedProperty {
    var name: SymbolRecord? { get }
    var datestamp: Date? { get }
    func typedValue(in store: Datastore) -> SemanticValue
    func encode(with encoder: InterchangeEncoder) -> Any?
    func encode(with encoder: InterchangeEncoder, into record: inout [String:Any])
}

extension NamedProperty {
    func encode(with encoder: InterchangeEncoder) -> Any? {
        var value: [String:Any] = [:]
        encode(with: encoder, into: &value)
        return value
    }
}
