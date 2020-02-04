// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public typealias ResolveResult = (EntityResolver, [EntityResolver])?

/// Object which is capable of finding (or possibly creating) an EntityRecord
public protocol EntityResolver {
    func resolve(in store: Datastore, for reference: EntityReference) -> ResolveResult
    func hash(into hasher: inout Hasher)
    func equal(to: EntityResolver) -> Bool
    var object: EntityRecord? { get }
    var identifier: String { get }
    var type: DatastoreType { get }
    var isResolved: Bool { get }
}

