// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct PropertyKey: Equatable, Hashable, ExpressibleByStringLiteral {
    public let value: String
    public let reference: EntityReference?
    
    public init(_ name: String) {
        self.value = name
        self.reference = nil
    }
    
    public init(array name: String) {
        self.value = name + "-" + UUID().uuidString
        self.reference = nil
    }
    
    public init(reference: EntityReference, name: String) {
        self.value = name
        self.reference = reference
    }
    
    public init(stringLiteral: String) {
        self.value = stringLiteral
        self.reference = nil
    }
    
    public init?(_ name: String?) {
        guard let name = name else { return nil }
        self.value = name
        self.reference = nil
    }

    public func resolve(in store: Datastore) -> (PropertyKey, [EntityRecord]) {
        guard let (entity, created) = reference?.resolve(in: store), let identifier = entity.identifier else{
            return (self, [])
        }
        
        return (PropertyKey("\(value)-\(identifier)"), created)
        
        // TODO: could we extract the resolve capabilities into a seperate protocol, so that most keys don't need the reference property?
    }
}

// MARK: - Standard Keys

public extension PropertyKey {
    static let conformsTo: Self = "conformsTo"
    static let datestamp: Self = "datestamp"
    static let entities: Self = "entities"
    static let identifier: Self = "identifier"
    static let name: Self = "name"
    static let type: Self = "type"
}

// MARK: - Debugging

extension PropertyKey: CustomStringConvertible {
    public var description: String {
        if let reference = reference {
            return "\(value)-(resolving: \(reference))"
        } else {
            return value
        }
    }
    
    
}
