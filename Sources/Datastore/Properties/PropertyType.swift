// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/11/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct PropertyType: Equatable, Hashable, ExpressibleByStringLiteral {
    public let name: String
    public init(_ name: String) { self.name = name }
    public init?(_ name: String?) {
        guard let name = name else { return nil }
        self.name = name
    }
    public init(stringLiteral: String) { self.name = stringLiteral }
}

// MARK: - Standard Types

public extension PropertyType {
    static let boolean: Self = "boolean"
    static let data: Self = "data"
    static let date: Self = "date"
    static let double: Self = "double"
    static let entity: Self = "entity"
    static let identifier: Self = "identifier"
    static let integer: Self = "integer"
    static let string: Self = "string"
    static let value: Self = "value"
}
