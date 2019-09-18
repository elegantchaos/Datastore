// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

public class EntityRecord: NSManagedObject {
    func add(property symbol: SymbolRecord, value: Any) {
        if let string = value as? String, let context = managedObjectContext {
            let property = StringPropertyRecord(context: context)
            property.value = string
            property.name = symbol
            property.owner = self
        }
    }
    
    func add(properties: [String:Any], store: Datastore) {
        for (key, value) in properties {
            add(property: store.symbol(named: key), value: value)
        }
    }
}
