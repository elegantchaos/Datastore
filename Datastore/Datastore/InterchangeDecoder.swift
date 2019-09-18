// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 18/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public protocol InterchangeDecoder {
    func decode(_ value: Any?) -> Any?
    func decode<T>(value: Any?, default defaultValue: @autoclosure () -> T) -> T
}

public extension InterchangeDecoder {
    func decode<T>(value: Any?, default defaultValue: @autoclosure () -> T) -> T {
        return (decode(value) as? T) ?? defaultValue()
    }
}

public struct NullInterchangeDecoder: InterchangeDecoder {
    public func decode(_ value: Any?) -> Any? {
        return value
    }
}


public struct JSONInterchangeDecoder: InterchangeDecoder {
    static let formatter = ISO8601DateFormatter()

    public func decode(_ value: Any?) -> Any? {
           if let record = value as? [String:Any] {
               if let date = record["date"] as? String {
                return JSONInterchangeDecoder.formatter.date(from: date) as Any
               }
           }
           
           return value
       }
    
}

