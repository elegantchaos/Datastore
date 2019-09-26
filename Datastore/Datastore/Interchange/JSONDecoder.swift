// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 26/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct JSONInterchangeDecoder: InterchangeDecoder {
    static let formatter = ISO8601DateFormatter()
    
    public func decodePrimitive(date: Any?) -> Date? {
        guard let string = date as? String else { return nil }
        return JSONInterchangeDecoder.formatter.date(from: string)
    }
    
    public func decodePrimitive(uuid: Any?) -> UUID? {
        guard let string = uuid as? String else { return nil }
        return UUID(uuidString: string)
    }
    
    public func decodePrimitive(data: Any?) -> Data? {
        guard let base64 = data as? String else { return nil }
        return Data(base64Encoded: base64)
    }
}

