// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/11/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData

class DatastoreModel: NSManagedObjectModel {
    override init() {
        super.init()
        setupEntities()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEntities()
    }
}

fileprivate extension DatastoreModel {
    func setupEntities() {
        let entityRecord = NSEntityDescription()
        entityRecord.name = "EntityRecord"
        entityRecord.managedObjectClassName = "Datastore.EntityRecord"
        
        let datestamp = NSAttributeDescription()
        datestamp.name = PropertyKey.datestamp.value
        datestamp.attributeType = .dateAttributeType
        datestamp.isOptional = false
        
        let type = NSAttributeDescription()
        type.name = PropertyKey.type.value
        type.attributeType = .stringAttributeType
        type.isOptional = false
        
        let identifier = NSAttributeDescription()
        identifier.name = PropertyKey.identifier.value
        identifier.attributeType = .stringAttributeType
        identifier.isOptional = false
        
        entityRecord.properties = [datestamp, type, identifier]
        self.entities = [
            entityRecord,
            makeEntity("Data", type: .binaryDataAttributeType, ownerEntity: entityRecord),
            makeEntity("Date", type: .dateAttributeType, ownerEntity: entityRecord),
            makeEntity("Double", type: .doubleAttributeType, ownerEntity: entityRecord),
            makeEntity("Integer", type: .integer64AttributeType, ownerEntity: entityRecord),
            makeEntity("Boolean", type: .booleanAttributeType, ownerEntity: entityRecord),
            makeRelationshipEntity(ownerEntity: entityRecord),
            makeEntity("String", type: .stringAttributeType, ownerEntity: entityRecord)
        ]
    }
    
    func makeEntity(_ entityName: String, type attributeType: NSAttributeType?, ownerEntity: NSEntityDescription) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name =  "\(entityName)Property"
        entity.managedObjectClassName = "Datastore.\(entityName)Property"
        let datestamp = NSAttributeDescription()
        datestamp.name = "datestamp"
        datestamp.attributeType = .dateAttributeType
        datestamp.isOptional = false
        
        let name = NSAttributeDescription()
        name.name = "name"
        name.attributeType = .stringAttributeType
        name.isOptional = false
        
        let type = NSAttributeDescription()
        type.name = "typeName"
        type.attributeType = .stringAttributeType
        type.isOptional = false
        
        let owner = NSRelationshipDescription()
        owner.name = "owner"
        owner.destinationEntity = ownerEntity
        owner.deleteRule = .nullifyDeleteRule
        owner.maxCount = 1
        owner.isOptional = false
        
        let ownerInverse = NSRelationshipDescription()
        ownerInverse.name = entityName.lowercased() + "s"
        ownerInverse.destinationEntity = entity
        owner.inverseRelationship = ownerInverse
        ownerInverse.inverseRelationship = owner
        ownerEntity.properties.append(ownerInverse)
        entity.properties = [datestamp, name, type, owner]
        
        if let attributeType = attributeType {
            let value = NSAttributeDescription()
            value.name = "value"
            value.attributeType = attributeType
            value.isOptional = false
            entity.properties.append(value)
        }
        
        return entity
    }
    
    func makeRelationshipEntity(ownerEntity: NSEntityDescription) -> NSEntityDescription {
        let relationship = makeEntity("Relationship", type: nil, ownerEntity: ownerEntity)
        
        let target = NSRelationshipDescription()
        target.name = "target"
        target.destinationEntity = ownerEntity
        target.deleteRule = .nullifyDeleteRule
        target.maxCount = 1
        target.isOptional = false
        
        let targets = NSRelationshipDescription()
        targets.name = "targets"
        targets.destinationEntity = relationship
        targets.isOptional = false
        
        target.inverseRelationship = targets
        targets.inverseRelationship = target
        
        relationship.properties.append(target)
        ownerEntity.properties.append(targets)
        
        return relationship
    }
}
