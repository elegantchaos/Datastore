// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

public class EntityRecord: NSManagedObject {
    typealias Key = PropertyKey
    
    @NSManaged public var datestamp: Date?
    @NSManaged public var type: String?
    @NSManaged public var identifier: String?
    
    @NSManaged public var booleans: NSSet?
    @NSManaged public var datas: NSSet?
    @NSManaged public var dates: NSSet?
    @NSManaged public var doubles: NSSet?
    @NSManaged public var integers: NSSet?
    @NSManaged public var strings: NSSet?
    @NSManaged public var relationships: NSSet?
    @NSManaged public var targets: NSSet?
    
    public override func awakeFromInsert() {
        if identifier == nil {
            identifier = UUID().uuidString
        }
        if datestamp == nil {
            datestamp = Date()
        }
    }
    
    /// Add a property entry record to this entity.
    /// If we're adding a relationship, resolving the reference to the related object
    /// might cause one or more objects to be created. We therefore return a list of
    /// created objects from this call; most of the time this will be empty.
    ///
    /// - Parameters:
    ///   - property: the property to add
    ///   - value: the property value
    ///   - store: the store to add to
    func add(property key: Key, value: PropertyValue, store: Datastore) -> [EntityRecord] {
        assert(managedObjectContext == store.context)
        
        let (property, createdByKey) = key.resolve(in: store)
        
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
            
            case let boolean as Bool:
                add(boolean, key: property, type: value.type, store: store)
            
            case let date as Date:
                add(date, key: property, type: value.type, store: store)
            
            case let data as Data:
                add(data, key: property, type: value.type, store: store)
            
            case let entity as EntityRecord:
                add(entity, key: property, type: value.type, store: store)
            
            case let entity as EntityReference:
                if let (resolved, created) = entity.resolve(in: store) {
                    add(resolved, key: property, type: value.type, store: store)
                    return created + createdByKey
            }
            
            case let entity as GuaranteedReference:
                if let (resolved, created) = entity.resolve(in: store) {
                    add(resolved, key: property, type: value.type, store: store)
                    return created + createdByKey
            }
            
            default:
                let unknown = Swift.type(of: value.value)
                print("unknown value type \(unknown) \(String(describing: value.value))")
                break
        }
        
        return []
    }
    
    func add(_ value: String, key: Key, type: PropertyType?, store: Datastore) {
        if let property: StringProperty = add(key: key, type: type ?? .string) {
            property.value = value
        }
    }
    
    func add(_ value: Int64, key: Key, type: PropertyType?, store: Datastore) {
        if let property: IntegerProperty = add(key: key, type: type ?? .integer) {
            property.value = value
        }
    }
    
    func add(_ value: Bool, key: Key, type: PropertyType?, store: Datastore) {
        if let property: BooleanProperty = add(key: key, type: type ?? .boolean) {
            property.value = value
        }
    }
    
    func add(_ value: Double, key: Key, type: PropertyType?, store: Datastore) {
        if let property: DoubleProperty = add(key: key, type: type ?? .double) {
            property.value = value
        }
    }
    
    func add(_ value: Date, key: Key, type: PropertyType?, store: Datastore) {
        if let property: DateProperty = add(key: key, type: type ?? .date) {
            property.value = value
        }
    }
    
    func add(_ value: Data, key: Key, type: PropertyType?, store: Datastore) {
        if let property: DataProperty = add(key: key, type: type ?? .data) {
            property.value = value
        }
    }
    
    func add(_ value: EntityRecord, key: Key, type: PropertyType?, store: Datastore) {
        if let property: RelationshipProperty = add(key: key, type: type ?? .entity) {
            property.target = value
        }
    }
    
    func read(properties names: Set<String>, store: Datastore) -> PropertyDictionary {
        assert(managedObjectContext == store.context)
        
        var values = PropertyDictionary()
        if names.contains(PropertyKey.datestamp.value) {
            values[valueWithKey: .datestamp] = PropertyValue(datestamp, type: .date)
        }
        if names.contains(PropertyKey.identifier.value) {
            values[valueWithKey: .identifier] = PropertyValue(identifier, type: .identifier)
        }
        if names.contains(PropertyKey.type.value) {
            values[valueWithKey: .type] = PropertyValue(type, type: .entity)
        }
        
        read(names: names, from: strings, as: StringProperty.self, into: &values, store: store)
        read(names: names, from: booleans, as: BooleanProperty.self, into: &values, store: store)
        read(names: names, from: integers, as: IntegerProperty.self, into: &values, store: store)
        read(names: names, from: doubles, as: DoubleProperty.self, into: &values, store: store)
        read(names: names, from: dates, as: DateProperty.self, into: &values, store: store)
        read(names: names, from: relationships, as: RelationshipProperty.self, into: &values, store: store)
        read(names: names, from: datas, as: DataProperty.self, into: &values, store: store)
        return values
    }
    
    func readAllProperties(store: Datastore) -> PropertyDictionary {
        assert(managedObjectContext == store.context)
        
        var values = PropertyDictionary()
        readAll(from: strings, as: StringProperty.self, into: &values, store: store)
        readAll(from: booleans, as: BooleanProperty.self, into: &values, store: store)
        readAll(from: integers, as: IntegerProperty.self, into: &values, store: store)
        readAll(from: doubles, as: DoubleProperty.self, into: &values, store: store)
        readAll(from: dates, as: DateProperty.self, into: &values, store: store)
        readAll(from: relationships, as: RelationshipProperty.self, into: &values, store: store)
        readAll(from: datas, as: DataProperty.self, into: &values, store: store)
        return values
    }
    
    func string(withKey key: Key) -> String? {
        if let strings = strings as? Set<StringProperty> {
            let names = strings.filter({ $0.name == key.value })
            let sorted = names.sorted(by: {$0.datestamp > $1.datestamp })
            return sorted.first?.value
        }
        return nil
    }
    
    func remove(properties names: Set<String>, store: Datastore) {
        assert(managedObjectContext == store.context)
        
        remove(names: names, from: strings, as: StringProperty.self, store: store)
        remove(names: names, from: integers, as: IntegerProperty.self, store: store)
        remove(names: names, from: doubles, as: DoubleProperty.self, store: store)
        remove(names: names, from: dates, as: DateProperty.self, store: store)
        remove(names: names, from: relationships, as: RelationshipProperty.self, store: store)
        remove(names: names, from: datas, as: DataProperty.self, store: store)
        remove(names: names, from: booleans, as: BooleanProperty.self, store: store)
    }
    
    // MARK: - Generic Helpers
    
    func add<R>(key: Key, type: PropertyType) -> R? where R: NamedProperty {
        guard let context = managedObjectContext else {
            return nil
        }
        
        let property = R(context: context)
        property.name = key.value
        property.owner = self
        property.typeName = type.name
        return property
    }
    
    
    func encode<T>(from properties: NSSet?, as: T.Type, into values: inout [String:Any], encoder: InterchangeEncoder) where T: NamedProperty {
        if let set = properties as? Set<T> {
            for property in set {
                values[property.name] = property.encode(with: encoder)
            }
        }
    }
    
    func read<T>(names: Set<String>, from properties: NSSet?, as: T.Type, into values: inout PropertyDictionary, store: Datastore) where T: NamedProperty {
        if let set = properties as? Set<T> {
            // there may be multiple entries for each property, so we sort them in date
            // order, and only return the newest one
            let sorted = set.sorted(by: { (p1, p2) in p1.datestamp > p2.datestamp })
            var remaining = names
            for property in sorted {
                let name = property.name
                if remaining.contains(name) {
                    let value = property.propertyValue
                    assert(value.type != nil)
                    values[valueWithKey: Key(name)] = value
                    remaining.remove(name)
                }
            }
        }
    }
    
    func readAll<T>(from properties: NSSet?, as: T.Type, into values: inout PropertyDictionary, store: Datastore) where T: NamedProperty {
        if let set = properties as? Set<T> {
            // there may be multiple entries for each property, so we sort them in date
            // order, and only return the newest one
            let sorted = set.sorted(by: { (p1, p2) in p1.datestamp > p2.datestamp })
            var done: Set<String> = []
            for property in sorted {
                let name = property.name
                if !done.contains(name) {
                    let value = property.propertyValue
                    assert(value.type != nil)
                    values[valueWithKey: Key(name)] = value
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
