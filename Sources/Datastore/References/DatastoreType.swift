// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/11/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Indicates the type of a property value, or an entity.
/// Can represent a semantic type (eg "Author"), or a fundamental storage type (eg "String")
/// Types can be arranged into a hierarchy (like UTI types), so that a high level type can conform
/// to a number of lower level types.
/// This hierarchy is optionally stored in the datastore itself, using entity records of type `.type`.
/// A translation table of types is built when the store is first loaded, and can be used by clients
/// of the store to resolve type relationships. Currently this table is only built once at load time,
/// so although new entries can be added (using the normal mechanisms for adding entities and setting
/// properties), they won't be picked up until the next time the store is loaded.

public struct DatastoreType: Equatable, Hashable, ExpressibleByStringLiteral {
    public let name: String
    public init(_ name: String) { self.name = name }
    public init?(_ name: String?) {
        guard let name = name else { return nil }
        self.name = name
    }
    public init(stringLiteral: String) { self.name = stringLiteral }
}

// MARK: - Standard Types

public extension DatastoreType {
    static let boolean: Self = "boolean"
    static let data: Self = "data"
    static let date: Self = "date"
    static let double: Self = "double"
    static let entity: Self = "entity"
    static let identifier: Self = "identifier"
    static let integer: Self = "integer"
    static let string: Self = "string"
    static let typeConformance: Self = "typeConformance"
    static let value: Self = "value"
}
