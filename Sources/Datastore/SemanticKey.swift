// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct SemanticKey: Equatable, Hashable, ExpressibleByStringLiteral {
    public let name: String
    public init(_ name: String) { self.name = name }
    public init?(_ name: String?) {
        guard let name = name else { return nil }
        self.name = name
    }
    public init(stringLiteral: String) { self.name = stringLiteral }
//    public var rawValue: String { return name }
}

// MARK: - Standard Names
public extension SemanticKey {
    static let data: Self = "data"
    static let datestamp: Self = "datestamp"
    static let date: Self = "date"
    static let double: Self = "double"
    static let entity: Self = "entity"
    static let entities: Self = "entities"
    static let identifier: Self = "identifier"
    static let integer: Self = "integer"
    static let name: Self = "name"
    static let string: Self = "string"
    static let type: Self = "type"
    static let value: Self = "value"
}
