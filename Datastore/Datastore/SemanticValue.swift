// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Wraps a normal value with an additional `type` tag.
/// This is a semantic type, indicating the purpose of the value (as opposed to its raw data type).

public struct SemanticValue {
    let value: Any?
    let type: SymbolID
    
    public func coerced<T>(or defaultValue: @autoclosure () -> T) -> T {
        return (value as? T) ?? defaultValue()
    }
}
