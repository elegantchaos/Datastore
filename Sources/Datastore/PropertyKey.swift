// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct PropertyKey: Equatable, Hashable, ExpressibleByStringLiteral {
    public let name: String
    public init(_ name: String) { self.name = name }
    public init(array name: String) { self.name = name + "-" + UUID().uuidString }
    public init(stringLiteral: String) { self.name = stringLiteral }
    public init?(_ name: String?) {
        guard let name = name else { return nil }
        self.name = name
    }
}

// MARK: - Standard Keys

public extension PropertyKey {
    static let datestamp: Self = "datestamp"
    static let entities: Self = "entities"
    static let identifier: Self = "identifier"
    static let name: Self = "name"
    static let type: Self = "type"
}
