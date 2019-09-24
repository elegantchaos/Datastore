// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData




public class EntityRecord: NSManagedObject {
    
    public override func awakeFromInsert() {
        if uuid == nil {
            uuid = UUID()
        }
        if datestamp == nil {
            datestamp = Date()
        }
    }
    
    func add(property symbolID: SymbolID, value: SemanticValue, store: Datastore) {
        if let context = managedObjectContext, let symbol = symbolID.resolve(in: context) {
            switch value.value {
            case let string as String:
                add(string, key: symbol, type: value.type, store: store)
                
            case let integer as Int16:
                add(Int64(integer), key: symbol, type: value.type, store: store)
                
            case let integer as Int32:
                add(Int64(integer), key: symbol, type: value.type, store: store)
                
            case let integer as Int64:
                add(integer, key: symbol, type: value.type, store: store)
                
            case let integer as Int:
                add(Int64(integer), key: symbol, type: value.type, store: store)
                
            case let integer as UInt16:
                add(Int64(integer), key: symbol, type: value.type, store: store)
                
            case let integer as UInt32:
                add(Int64(integer), key: symbol, type: value.type, store: store)
                
            case let integer as UInt64:
                add(Int64(integer), key: symbol, type: value.type, store: store)
                
            case let integer as UInt:
                add(Int64(integer), key: symbol, type: value.type, store: store)
                
            case let double as Double:
                add(double, key: symbol, type: value.type, store: store)
                
            case let date as Date:
                add(date, key: symbol, type: value.type, store: store)
                
            case let entity as EntityRecord:
                add(entity, key: symbol, type: value.type, store: store)
                
            case let entity as EntityID:
                if let resolved = entity.resolve(in: context) {
                    add(resolved, key: symbol, type: value.type, store: store)
                }

            case let entity as Entity:
                if let resolved = entity.resolve(in: context) {
                    add(resolved, key: symbol, type: value.type, store: store)
                }

            default:
                let unknown = Swift.type(of: value.value)
                print("unknown value type \(unknown) \(String(describing: value.value))")
                break
            }
        }
    }
    func add(_ value: String, key: SymbolRecord, type: SymbolID?, store: Datastore) {
        if let property: StringProperty = add(key: key, type: type ?? store.standardSymbols.string) {
            property.value = value
        }
    }
    
    func add(_ value: Int64, key: SymbolRecord, type: SymbolID?, store: Datastore) {
        if let property: IntegerProperty = add(key: key, type: type ?? store.standardSymbols.integer) {
            property.value = value
        }
    }
    
    func add(_ value: Double, key: SymbolRecord, type: SymbolID?, store: Datastore) {
        if let property: DoubleProperty = add(key: key, type: type ?? store.standardSymbols.double) {
            property.value = value
        }
    }
    
    func add(_ value: Date, key: SymbolRecord, type: SymbolID?, store: Datastore) {
        if let property: DateProperty = add(key: key, type: type ?? store.standardSymbols.date) {
            property.value = value
        }
    }
    
    func add(_ value: EntityRecord, key: SymbolRecord, type: SymbolID?, store: Datastore) {
        if let property: RelationshipProperty = add(key: key, type: type ?? store.standardSymbols.entity) {
            property.target = value
        }
    }
    
    
    func read(properties names: Set<String>, store: Datastore) -> SemanticDictionary {
        var values = SemanticDictionary()
        if names.contains("datestamp") {
            values[valueWithKey: "datestamp"] = store.value(datestamp, type: store.standardSymbols.date)
        }
        if names.contains("uuid") {
            values[valueWithKey: "uuid"] = store.value(uuid, type: store.standardSymbols.identifier)
        }
        if names.contains("type") {
            values[valueWithKey: "type"] = store.value(type?.uuid, type: store.standardSymbols.entity)
        }

        read(names: names, from: strings, as: StringProperty.self, into: &values, store: store)
        read(names: names, from: integers, as: IntegerProperty.self, into: &values, store: store)
        read(names: names, from: doubles, as: DoubleProperty.self, into: &values, store: store)
        read(names: names, from: dates, as: DateProperty.self, into: &values, store: store)
        read(names: names, from: relationships, as: RelationshipProperty.self, into: &values, store: store)
        return values
    }
    
    func readAllProperties(store: Datastore) -> SemanticDictionary {
        var values = SemanticDictionary()
        readAll(from: strings, as: StringProperty.self, into: &values, store: store)
        readAll(from: integers, as: IntegerProperty.self, into: &values, store: store)
        readAll(from: doubles, as: DoubleProperty.self, into: &values, store: store)
        readAll(from: dates, as: DateProperty.self, into: &values, store: store)
        readAll(from: relationships, as: RelationshipProperty.self, into: &values, store: store)
        return values
    }
    
    func string(withKey keyID: SymbolID) -> String? {
        if let context = managedObjectContext, let key = keyID.resolve(in: context), let strings = strings as? Set<StringProperty> {
            let names = strings.filter({ $0.name == key })
            let sorted = names.sorted(by: {$0.datestamp! > $1.datestamp! })
            return sorted.first?.value
        }
        return nil
    }
    
    func remove(properties names: Set<String>, store: Datastore) {
        remove(names: names, from: strings, as: StringProperty.self, store: store)
        remove(names: names, from: integers, as: IntegerProperty.self, store: store)
        remove(names: names, from: doubles, as: DoubleProperty.self, store: store)
        remove(names: names, from: dates, as: DateProperty.self, store: store)
        remove(names: names, from: relationships, as: RelationshipProperty.self, store: store)
    }
    
    // MARK: - Generic Helpers
    
    func add<R>(key: SymbolRecord, type: SymbolID) -> R? where R: NamedProperty {
        guard let context = managedObjectContext else {
            return nil
        }
        
        let property = R(context: context)
        property.name = key
        property.owner = self
        property.type = type.resolve(in: context)
        assert(property.type != nil)
        return property
    }
    
    
    func encode<T>(from properties: NSSet?, as: T.Type, into values: inout [String:Any], encoder: InterchangeEncoder) where T: NamedProperty {
        if let set = properties as? Set<T> {
            for property in set {
                if let name = property.name?.name {
                    values[name] = property.encode(with: encoder)
                }
            }
        }
    }
    
    func read<T>(names: Set<String>, from properties: NSSet?, as: T.Type, into values: inout SemanticDictionary, store: Datastore) where T: NamedProperty {
        if let set = properties as? Set<T> {
            // there may be multiple entries for each property, so we sort them in date
            // order, and only return the newest one
            let sorted = set.sorted(by: { (p1, p2) in p1.datestamp! > p2.datestamp! })
            var remaining = names
            for property in sorted {
                if let name = property.name?.name, remaining.contains(name) {
                    let value = property.typedValue(in: store)
                    assert(value.type != nil)
                    values[valueWithKey: name] = value
                    remaining.remove(name)
                }
            }
        }
    }

    func readAll<T>(from properties: NSSet?, as: T.Type, into values: inout SemanticDictionary, store: Datastore) where T: NamedProperty {
        if let set = properties as? Set<T> {
            // there may be multiple entries for each property, so we sort them in date
            // order, and only return the newest one
            let sorted = set.sorted(by: { (p1, p2) in p1.datestamp! > p2.datestamp! })
            var done: Set<String> = []
            for property in sorted {
                if let name = property.name?.name, !done.contains(name) {
                    let value = property.typedValue(in: store)
                    assert(value.type != nil)
                    values[valueWithKey: name] = value
                    done.insert(name)
                }
            }
        }
    }
    
    func remove<T>(names: Set<String>, from properties: NSSet?, as: T.Type, store: Datastore) where T: NamedProperty {
        if let set = properties as? Set<T> {
            for property in set {
                if let name = property.name?.name, names.contains(name) {
                    property.managedObjectContext?.delete(property)
                }
            }
        }
    }
}
