// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData




public class EntityRecord: NSManagedObject {
    func add(property symbol: SymbolRecord, value: SemanticValue) {
        switch value.value {
        case let string as String:
            add(string, key: symbol, type: value.type)
            
        case let integer as Int:
            add(integer, key: symbol, type: value.type)
            
        case let date as Date:
            add(date, key: symbol, type: value.type)

        case let entity as EntityRecord:
            add(entity, key: symbol, type: value.type)
        
        case let entity as EntityID:
            if let context = managedObjectContext, let resolved = entity.resolve(in: context) {
                add(resolved, key: symbol, type: value.type)
            }

        default:
            print("unknown value type \(value)")
            break
        }
    }
    
    func add(_ value: String, key: SymbolRecord, type: SymbolID) {
        if let context = managedObjectContext {
            let property = StringPropertyRecord(context: context)
            property.value = value
            property.name = key
            property.owner = self
            property.type = type.resolve(in: context)
        }
    }
    
    func add(_ value: Int, key: SymbolRecord, type: SymbolID) {
        if let context = managedObjectContext {
            let property = IntegerPropertyRecord(context: context)
            property.value = Int64(value)
            property.name = key
            property.owner = self
            property.type = type.resolve(in: context)
        }
    }
    
    func add(_ value: Date, key: SymbolRecord, type: SymbolID) {
        if let context = managedObjectContext {
            let property = DatePropertyRecord(context: context)
            property.value = value
            property.name = key
            property.owner = self
            property.type = type.resolve(in: context)
        }
    }
    
    func add(_ entity: EntityRecord, key: SymbolRecord, type: SymbolID) {
        if let context = managedObjectContext {
            let property = RelationshipProperty(context: context)
            property.target = entity
            property.name = key
            property.owner = self
            property.type = type.resolve(in: context)
        }
    }
    
    func add(properties: [String:Any], store: Datastore) {
        for (key, value) in properties {
            add(property: store.symbol(named: key), value: store.value(value))
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
    
    func read<T>(names: Set<String>, from properties: NSSet?, as: T.Type, into values: inout SemanticDictionary, store: Datastore) where T: NamedProperty, T: Hashable {
        if let set = properties as? Set<T> {
            for property in set {
                if let name = property.name?.name, names.contains(name) {
                    values[valueWithKey: name] = property.typedValue(in: store)
                }
            }
        }
    }
}
