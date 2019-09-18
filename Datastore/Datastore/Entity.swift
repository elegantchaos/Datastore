// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

@objc protocol NamedProperty {
    var name: SymbolRecord? { get }
    var valueX: Any? { get }
}

extension StringPropertyRecord: NamedProperty {
    var valueX: Any? {
        return value
    }
}

extension IntegerPropertyRecord: NamedProperty {
    var valueX: Any? {
        return value
    }
}

extension DatePropertyRecord: NamedProperty {
    var valueX: Any? {
        return value
    }
}

public class EntityRecord: NSManagedObject {
    func add(property symbol: SymbolRecord, value: Any) {
        switch value {
        case let string as String:
            add(property: symbol, string: string)

        default:
            break
        }
    }
    
    func add(property symbol: SymbolRecord, string: String) {
        if let context = managedObjectContext {
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
    
    func read<T>(names: Set<String>, from properties: NSSet?, as: T.Type, into values: inout [String:Any]) where T: NamedProperty, T: Hashable {
        if let set = properties as? Set<T> {
            for property in set {
                if let name = property.name?.name, names.contains(name) {
                    values[name] = property.valueX
                }
            }
        }
    }
}
