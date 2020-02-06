// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension Dictionary {
    @inlinable public mutating func mergeReplacingDuplicates<S>(_ other: S) where S : Sequence, S.Element == (Key, Value) {
        merge(other, uniquingKeysWith: { current, new in new })
    }

    @inlinable public mutating func mergeReplacingDuplicates(_ other: [Key : Value]) {
        merge(other, uniquingKeysWith: { current, new in new })
    }

    @inlinable public mutating func mergeNewOnly<S>(_ other: S) where S : Sequence, S.Element == (Key, Value) {
        merge(other, uniquingKeysWith: { current, new in current })
    }

    @inlinable public mutating func mergeNewOnly(_ other: [Key : Value]) {
        merge(other, uniquingKeysWith: { current, new in current })
    }

}
