// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/02/20.
//  All code (c) 2020 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Datastore

public class DatastorePropertyLayout {
    public struct SectionEntry {
        let key: PropertyKey
        let value: PropertyValue
        let viewer: DatastorePropertyView.Type
    }
    
    var valueViews: [DatastoreType : DatastorePropertyView.Type] = [
        .boolean: BooleanPropertyView.self,
        .date: DatePropertyView.self,
        .double: DoublePropertyView.self,
        .entity: RelationshipPropertyView.self,
        .integer: IntegerPropertyView.self,
        .string: StringPropertyView.self,
    ]
    
    
      func registeredViewClass(for value: PropertyValue) -> DatastorePropertyView.Type {
          if let type = value.type {
              if let entry = valueViews[type] {
                  // if we have a specific view for the value type, use it
                  return entry
              }

            for conformance in store.conformances(for: type) {
                // if we have a view for the mapped value type, use that
                if let entry = valueViews[conformance] {
                  return entry
                }
              }
          }
          
          return GenericPropertyView.self
      }

    public typealias SectionOrder = [SectionEntry]
    public typealias SectionsList = [SectionOrder]

    public let store: Datastore
    public var sections: SectionsList
    
    public init(with properties: PropertyDictionary, from store: Datastore) {
        self.store = store
        self.sections = []
        
        var section: SectionOrder = []
        let keys = properties.keys.sorted(by: { $0.value < $1.value })
        for key in keys {
            if let value = properties[valueWithKey: key] {
                let viewer = registeredViewClass(for: value)
                let entry = SectionEntry(key: key, value: value, viewer: viewer)
                section.append(entry)
            }
        }
        sections.append(section)
    }
}
