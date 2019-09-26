// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 26/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct JSONInterchangeEncoder: InterchangeEncoder {
    static let formatter = ISO8601DateFormatter()

    public func encodePrimitive(_ date: Date?) -> Any? {
        guard let date = date else {
            return nil
        }
        
        return JSONInterchangeEncoder.formatter.string(from: date)
    }

    public func encodePrimitive(_ uuid: UUID?) -> Any? {
        return uuid?.uuidString
    }
    
    public func encodePrimitive(_ data: Data?) -> Any? {
        return data?.base64EncodedString()
    }
}

