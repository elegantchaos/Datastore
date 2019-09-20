// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData




public class EntityRecord: NSManagedObject {
    func add(property symbolID: SymbolID, value: SemanticValue, store: Datastore) {
        if let context = managedObjectContext, let symbol = symbolID.resolve(in: context) {
            switch value.value {
            case let string as String:
                add(string, key: symbol, type: value.type, store: store)
                
            case let integer as Int:
                add(integer, key: symbol, type: value.type, store: store)
                
            case let date as Date:
                add(date, key: symbol, type: value.type, store: store)

            case let entity as EntityRecord:
                add(entity, key: symbol, type: value.type, store: store)
            
            case let entity as EntityID:
                if let resolved = entity.resolve(in: context) {
                    add(resolved, key: symbol, type: value.type, store: store)
                }

            default:
                print("unknown value type \(value)")
                break
            }
        }
    }
    
    func add(_ value: String, key: SymbolRecord, type: SymbolID?, store: Datastore) {
        if let context = managedObjectContext {
            let property = StringProperty(context: context)
            property.value = value
            property.name = key
            property.owner = self
            property.type = (type ?? store.stringSymbol).resolve(in: context)
            assert(property.type != nil)
        }
    }
    
    func add(_ value: Int, key: SymbolRecord, type: SymbolID?, store: Datastore) {
        if let context = managedObjectContext {
            let property = IntegerProperty(context: context)
            property.value = Int64(value)
            property.name = key
            property.owner = self
            property.type = (type ?? store.numberSymbol).resolve(in: context)
            assert(property.type != nil)
        }
    }
    
    func add(_ value: Date, key: SymbolRecord, type: SymbolID?, store: Datastore) {
        if let context = managedObjectContext {
            let property = DateProperty(context: context)
            property.value = value
            property.name = key
            property.owner = self
            property.type = (type ?? store.dateSymbol).resolve(in: context)
            assert(property.type != nil)
        }
    }
    
    func add(_ entity: EntityRecord, key: SymbolRecord, type: SymbolID?, store: Datastore) {
        if let context = managedObjectContext {
            let property = RelationshipProperty(context: context)
            property.target = entity
            property.name = key
            property.owner = self
            property.type = (type ?? store.entitySymbol).resolve(in: context)
            assert(property.type != nil)
        }
    }

    func encode<T>(from properties: NSSet?, as: T.Type, into values: inout [String:Any], encoder: InterchangeEncoder) where T: NamedProperty, T: Hashable {
        if let set = properties as? Set<T> {
            for property in set {
                if let name = property.name?.name {
                    values[name] = property.encode(with: encoder)
                }
            }
        }
    }
    
    func read(properties names: Set<String>, store: Datastore) -> SemanticDictionary {
        var values = SemanticDictionary()
        for property in Datastore.specialProperties {
            if names.contains(property) {
                values[valueWithKey: property] = store.value(value(forKey: property))
            }
        }
        read(names: names, from: strings, as: StringProperty.self, into: &values, store: store)
        read(names: names, from: integers, as: IntegerProperty.self, into: &values, store: store)
        read(names: names, from: dates, as: DateProperty.self, into: &values, store: store)
        read(names: names, from: relationships, as: RelationshipProperty.self, into: &values, store: store)
        return values
    }
    
    func read<T>(names: Set<String>, from properties: NSSet?, as: T.Type, into values: inout SemanticDictionary, store: Datastore) where T: NamedProperty, T: Hashable {
        if let set = properties as? Set<T> {
            for property in set {
                if let name = property.name?.name, names.contains(name) {
                    let value = property.typedValue(in: store)
                    assert(value.type != nil)
                    values[valueWithKey: name] = value
                }
            }
        }
    }
}
