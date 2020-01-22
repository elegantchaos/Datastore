// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Wraps a normal value with an additional `type` and `datestamp`.
/// The type is semantic label, indicating the purpose of the value (as opposed to its raw data type).
/// It is not interpreted by Datastore, just passed along faithfully, so clients of the datastore can use
/// it however they wish. For example a user interface might use the type value to choose which
/// view subclass to use to display a property.

public struct PropertyValue {
    public let value: Any?
    public let type: PropertyType?
    public let datestamp: Date?
    
    init(_ value: Any?, type: PropertyType? = .value, datestamp: Date? = Date()) {
        self.value = value
        self.type = type
        self.datestamp = datestamp
    }
    
    public func coerced<T>(or defaultValue: @autoclosure () -> T) -> T {
        return (value as? T) ?? defaultValue()
    }
}
