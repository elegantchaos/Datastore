// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

protocol NamedProperty {
    var name: SymbolRecord? { get }
    var valueX: Any? { get }
    func encode(encoder: InterchangeEncoder) -> Any?
}

extension StringPropertyRecord: NamedProperty {
    var valueX: Any? {
        return value
    }
    func encode(encoder: InterchangeEncoder) -> Any? {
        return encoder.encode(value)
    }
}

extension IntegerPropertyRecord: NamedProperty {
    var valueX: Any? {
        return value
    }
    func encode(encoder: InterchangeEncoder) -> Any? {
        return encoder.encode(value)
    }
}

extension DatePropertyRecord: NamedProperty {
    var valueX: Any? {
        return value
    }
    func encode(encoder: InterchangeEncoder) -> Any? {
        return encoder.encode(value)
    }
}

public class EntityRecord: NSManagedObject {
    func add(property symbol: SymbolRecord, value: Any) {
        switch value {
        case let string as String:
            add(string, key: symbol)

        case let integer as Int:
            add(integer, key: symbol)

        case let date as Date:
            add(date, key: symbol)

        default:
            break
        }
    }
    
    func add(_ value: String, key: SymbolRecord) {
        if let context = managedObjectContext {
            let property = StringPropertyRecord(context: context)
            property.value = value
            property.name = key
            property.owner = self
        }
    }

    func add(_ value: Int, key: SymbolRecord) {
        if let context = managedObjectContext {
            let property = IntegerPropertyRecord(context: context)
            property.value = Int64(value)
            property.name = key
            property.owner = self
        }
    }

    func add(_ value: Date, key: SymbolRecord) {
        if let context = managedObjectContext {
            let property = DatePropertyRecord(context: context)
            property.value = value
            property.name = key
            property.owner = self
        }
    }

    func add(properties: [String:Any], store: Datastore) {
        for (key, value) in properties {
            add(property: store.symbol(named: key), value: value)
        }
    }

    func encode<T>(from properties: NSSet?, as: T.Type, into values: inout [String:Any], encoder: InterchangeEncoder) where T: NamedProperty, T: Hashable {
        if let set = properties as? Set<T> {
            for property in set {
                if let name = property.name?.name {
                    values[name] = property.encode(encoder: encoder)
                }
            }
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
