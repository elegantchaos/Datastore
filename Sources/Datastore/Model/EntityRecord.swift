// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData




public class EntityRecord: NSManagedObject {
    @NSManaged public var datestamp: Date?
    @NSManaged public var type: String?
    @NSManaged public var uuid: UUID?
    
    @NSManaged public var datas: NSSet?
    @NSManaged public var dates: NSSet?
    @NSManaged public var doubles: NSSet?
    @NSManaged public var integers: NSSet?
    @NSManaged public var strings: NSSet?
    @NSManaged public var relationships: NSSet?
    @NSManaged public var targets: NSSet?

    public override func awakeFromInsert() {
        if uuid == nil {
            uuid = UUID()
        }
        if datestamp == nil {
            datestamp = Date()
        }
    }
    
    func add(property: String, value: SemanticValue, store: Datastore) {
        if let context = managedObjectContext {
            switch value.value {
            case let string as String:
                add(string, key: property, type: value.type, store: store)
                
            case let integer as Int16:
                add(Int64(integer), key: property, type: value.type, store: store)
                
            case let integer as Int32:
                add(Int64(integer), key: property, type: value.type, store: store)
                
            case let integer as Int64:
                add(integer, key: property, type: value.type, store: store)
                
            case let integer as Int:
                add(Int64(integer), key: property, type: value.type, store: store)
                
            case let integer as UInt16:
                add(Int64(integer), key: property, type: value.type, store: store)
                
            case let integer as UInt32:
                add(Int64(integer), key: property, type: value.type, store: store)
                
            case let integer as UInt64:
                add(Int64(integer), key: property, type: value.type, store: store)
                
            case let integer as UInt:
                add(Int64(integer), key: property, type: value.type, store: store)
                
            case let double as Double:
                add(double, key: property, type: value.type, store: store)
                
            case let date as Date:
                add(date, key: property, type: value.type, store: store)
                
            case let data as Data:
                add(data, key: property, type: value.type, store: store)
                
            case let entity as EntityRecord:
                add(entity, key: property, type: value.type, store: store)
                
            case let entity as EntityID:
                if let resolved = entity.resolve(in: context) {
                    add(resolved, key: property, type: value.type, store: store)
                }

            case let entity as Entity:
                if let resolved = entity.resolve(in: context) {
                    add(resolved, key: property, type: value.type, store: store)
                }

            default:
                let unknown = Swift.type(of: value.value)
                print("unknown value type \(unknown) \(String(describing: value.value))")
                break
            }
        }
    }
    
    func add(_ value: String, key: String, type: String?, store: Datastore) {
        if let property: StringProperty = add(key: key, type: type ?? Datastore.standardNames.string) {
            property.value = value
        }
    }
    
    func add(_ value: Int64, key: String, type: String?, store: Datastore) {
        if let property: IntegerProperty = add(key: key, type: type ?? Datastore.standardNames.integer) {
            property.value = value
        }
    }
    
    func add(_ value: Double, key: String, type: String?, store: Datastore) {
        if let property: DoubleProperty = add(key: key, type: type ?? Datastore.standardNames.double) {
            property.value = value
        }
    }
    
    func add(_ value: Date, key: String, type: String?, store: Datastore) {
        if let property: DateProperty = add(key: key, type: type ?? Datastore.standardNames.date) {
            property.value = value
        }
    }

    func add(_ value: Data, key: String, type: String?, store: Datastore) {
        if let property: DataProperty = add(key: key, type: type ?? Datastore.standardNames.data) {
            property.value = value
        }
    }

    func add(_ value: EntityRecord, key: String, type: String?, store: Datastore) {
        if let property: RelationshipProperty = add(key: key, type: type ?? Datastore.standardNames.entity) {
            property.target = value
        }
    }
        
    func read(properties names: Set<String>, store: Datastore) -> SemanticDictionary {
        var values = SemanticDictionary()
        if names.contains(Datastore.standardNames.datestamp) {
            values[valueWithKey: Datastore.standardNames.datestamp] = SemanticValue(datestamp, type: Datastore.standardNames.date)
        }
        if names.contains(Datastore.standardNames.uuid) {
            values[valueWithKey: Datastore.standardNames.uuid] = SemanticValue(uuid, type: Datastore.standardNames.identifier)
        }
        if names.contains(Datastore.standardNames.type) {
            values[valueWithKey: Datastore.standardNames.type] = SemanticValue(type, type: Datastore.standardNames.entity)
        }

        read(names: names, from: strings, as: StringProperty.self, into: &values, store: store)
        read(names: names, from: integers, as: IntegerProperty.self, into: &values, store: store)
        read(names: names, from: doubles, as: DoubleProperty.self, into: &values, store: store)
        read(names: names, from: dates, as: DateProperty.self, into: &values, store: store)
        read(names: names, from: relationships, as: RelationshipProperty.self, into: &values, store: store)
        read(names: names, from: datas, as: DataProperty.self, into: &values, store: store)
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
    
    func string(withKey key: String) -> String? {
        if let strings = strings as? Set<StringProperty> {
            let names = strings.filter({ $0.name == key })
            let sorted = names.sorted(by: {$0.datestamp > $1.datestamp })
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
    
    func add<R>(key: String, type: String) -> R? where R: NamedProperty {
        guard let context = managedObjectContext else {
            return nil
        }
        
        let property = R(context: context)
        property.name = key
        property.owner = self
        property.type = type
        return property
    }
    
    
    func encode<T>(from properties: NSSet?, as: T.Type, into values: inout [String:Any], encoder: InterchangeEncoder) where T: NamedProperty {
        if let set = properties as? Set<T> {
            for property in set {
                values[property.name] = property.encode(with: encoder)
            }
        }
    }
    
    func read<T>(names: Set<String>, from properties: NSSet?, as: T.Type, into values: inout SemanticDictionary, store: Datastore) where T: NamedProperty {
        if let set = properties as? Set<T> {
            // there may be multiple entries for each property, so we sort them in date
            // order, and only return the newest one
            let sorted = set.sorted(by: { (p1, p2) in p1.datestamp > p2.datestamp })
            var remaining = names
            for property in sorted {
                let name = property.name
                if remaining.contains(name) {
                    let value = property.semanticValue
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
            let sorted = set.sorted(by: { (p1, p2) in p1.datestamp > p2.datestamp })
            var done: Set<String> = []
            for property in sorted {
                let name = property.name
                if !done.contains(name) {
                    let value = property.semanticValue
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
                let name = property.name
                if names.contains(name) {
                    property.managedObjectContext?.delete(property)
                }
            }
        }
    }
}
