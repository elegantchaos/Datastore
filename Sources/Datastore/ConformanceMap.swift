// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Logger

let conformanceChannel = Channel("com.elegantchaos.datastore.conformance")

public class ConformanceMap {
    internal class ConformanceSet {
        var types: Set<DatastoreType> = []
        init(_ type: DatastoreType) {
            self.types = [type]
        }
    }

    var map: [DatastoreType: ConformanceSet]
    
    init() {
        map = [:]
    }

    /// Returns the list of types that another type conforms to.
    ///
    /// All entity types that have records in the store are guaranteed to
    /// conform to at least the type `.entity`.
    /// Other metadata entries can exist in the database itself, which describe
    /// either the types of entities, or the types of properties.
    ///
    /// For example:
    /// - the type "author" might conform to "person" and "entity"
    /// - the type "address" might conform to "string"
    ///
    /// - Parameter type: the type to look up
    func conformances(for type: DatastoreType) -> [DatastoreType] {
        if let entries = map[type] {
            return Array(entries.types)
        } else {
            return []
        }
    }

    /// Mark a type as conforming to another type.
    /// - Parameters:
    ///   - type: type to mark
    ///   - otherType: type it conforms to
    func addConformance(for type: DatastoreType, to otherType: DatastoreType) {
        if let set = map[type] {
            set.types.insert(otherType)
        } else {
            map[type] = ConformanceSet(otherType)
        }
    }

    
    /// For every type in the map, we merge in the entries of any types that
    /// it conforms to, so that the entry for each type contains the full list
    /// of types it conforms to.
    ///
    /// By way of an example, it will transform a map
    ///  from: A -> [B], B -> [C], C -> [D]
    ///    to: A -> [B,C,D], B -> [C, D], C -> [D]
    
    func expandConformanceRecords() {
        var changed: Bool
        repeat {
            changed = false
            for (type, values) in map {
                for subtype in values.types {
                    if let subValues = map[subtype]?.types {
                        let count = values.types.count
                        values.types.formUnion(subValues)
                        if values.types.count > count {
                            conformanceChannel.log("Merged conformances \(subValues.map { $0.name }) from \(subtype.name) into \(type.name).")
                            changed = true
                        }
                    }
                }
            }
        } while (changed)
        conformanceChannel.log("Resolved conformance map:\n\n\(map)")
    }

}
