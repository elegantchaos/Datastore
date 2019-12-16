// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

//public protocol PropertyKey: Equatable, Hashable,  {
//    var value: String { get }
//    func resolve(in store: Datastore) -> PropertyKey
//}
//
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

    public func resolve(in store: Datastore) -> PropertyKey {
        guard let (entity, _) = reference?.resolve(in: store), let identifier = entity.identifier else{
            return self
        }
        
        return PropertyKey("\(value)-\(identifier)")
    }
}
//
//extension PropertyKey: ExpressibleByStringLiteral {
//
//}

//
//public protocol ResolvablePropertyKey {
//    func resolve(in store: Datastore) -> PropertyKey
//}
//
//extension PropertyKey: ResolvablePropertyKey {
//    public func resolve(in store: Datastore) -> PropertyKey {
//        return self
//    }
//}
//
//public struct ReferenceKey: PropertyKey {
//    public let name: String
//    public let reference: EntityReference? = nil
//
//    public func resolve(in store: Datastore) -> PropertyKey {
//        guard let (entity, _) = reference?.resolve(in: store), let identifier = entity.identifier else{
//            return PropertyKey(name)
//        }
//
//        return PropertyKey("\(name)-\(identifier)")
//    }
//
//}

// MARK: - Standard Keys

public extension PropertyKey {
    static let datestamp: Self = "datestamp"
    static let entities: Self = "entities"
    static let identifier: Self = "identifier"
    static let name: Self = "name"
    static let type: Self = "type"
}
