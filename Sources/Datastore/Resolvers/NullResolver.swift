// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/12/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Always resolves to a null entity.
internal struct NullResolver: EntityResolver {
    internal func resolve(in store: Datastore, for reference: EntityReference) -> ResolveResult { return nil }
    internal var object: EntityRecord? { return nil }
    func hash(into hasher: inout Hasher) { 0.hash(into: &hasher) }
    func equal(to other: EntityResolver) -> Bool { return other is NullResolver }
    var identifier: String { return EntityReference.nullIdentifier }
    var type: DatastoreType { return .null }
    var isResolved: Bool { return true }
}

