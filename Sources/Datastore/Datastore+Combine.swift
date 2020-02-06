// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if canImport(Combine)

import Combine
import Foundation

extension DatastoreContainer {
    
    @available(macOS 10.15, *) public class func loadCombine(name: String, url: URL? = nil) -> Future<ContainerWithStore, Error> {
        let future = Future<ContainerWithStore, Error>() { promise in
            load(name: name, url: url) { result in
                promise(result)
            }
        }
        
        return future
    }

}

#endif
