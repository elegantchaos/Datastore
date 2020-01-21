// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData

extension Datastore {
    
    public func decode(json: String, completion: @escaping (LoadResult) -> Void) {
        guard let data = json.data(using: .utf8) else {
            completion(.failure(InvalidJSONError()))
            return
        }
        
        do {
            if let interchange = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                decode(interchange: interchange, decoder: JSONInterchangeDecoder(), completion: completion)
            } else {
                completion(.failure(InvalidJSONError()))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    public func decode(interchange: [String:Any], decoder: InterchangeDecoder, completion: @escaping (LoadResult) -> Void) {
        decodeEntities(from: interchange, with: decoder)
        try? context.save()
        completion(.success(self))
    }

 
    fileprivate func decodeEntities(from interchange: [String : Any], with decoder: InterchangeDecoder) {
        if let entities = interchange[PropertyKey.entities.value] as? [[String:Any]] {
            for entityRecord in entities {
                // TODO: allow missing identifiers?
                // TODO: warn when identifier or type is missing?
                if let identifier = entityRecord[PropertyKey.identifier.value] as? String, let type = entityRecord[PropertyKey.type.value] as? String {
                    var entity = EntityRecord.withIdentifier(identifier, in: context)
                    if entity == nil {
                        let newEntity = EntityRecord(in: context)
                        newEntity.identifier = identifier
                        newEntity.type = type
                        entity = newEntity
                        try? context.save()
                    }
                    if let entity = entity {
                        decodeEntity(entity, with: decoder, values: entityRecord)
                    }
                }
            }
        }
    }
    
    fileprivate func decodeEntity(_ entity: EntityRecord, with decoder: InterchangeDecoder, values entityRecord: [String : Any]) {
        entity.datestamp = decoder.decode(entityRecord[PropertyKey.datestamp.value], store: self).coerced(or: Date())
         var entityProperties = entityRecord
         for key in Datastore.specialProperties {
            entityProperties.removeValue(forKey: key.value)
         }
        decode(properties: entityProperties, of: entity, with: decoder)
     }
     
    fileprivate func decode(properties: [String:Any], of entity: EntityRecord, with decoder: InterchangeDecoder) {
        for (key, value) in properties {
            let _ = entity.add(property: PropertyKey(key), value: decoder.decode(value, store: self), store: self)
        }
    }

    public func encodeInterchange(encoder: InterchangeEncoder = NullInterchangeEncoder(), completion: @escaping InterchangeCompletion) {
        let context = self.context
        context.perform {
            var entityResults: [[String:Any]] = []
            let request: NSFetchRequest<EntityRecord> = EntityRecord.fetcher(in: context) // TODO: can we remove need for type declaration?
            if let entities = try? context.fetch(request) {
                for entity in entities {
                    var record: [String:Any] = [:]
                    record[PropertyKey.type.value] = entity.type
                    record[PropertyKey.datestamp.value] = encoder.encodePrimitive(entity.datestamp)
                    record[PropertyKey.identifier.value] = entity.identifier
                    entity.encode(from: entity.strings, as: StringProperty.self, into: &record, encoder: encoder)
                    entity.encode(from: entity.integers, as: IntegerProperty.self, into: &record, encoder: encoder)
                    entity.encode(from: entity.dates, as: DateProperty.self, into: &record, encoder: encoder)
                    entity.encode(from: entity.relationships, as: RelationshipProperty.self, into: &record, encoder: encoder)
                    entity.encode(from: entity.datas, as: DataProperty.self, into: &record, encoder: encoder)
                    entityResults.append(record)
                }
            }
            let result = [
                PropertyKey.entities.value : entityResults
            ]
            completion(result)
        }
    }
    
    public func encodeJSON(completion: @escaping (String) -> Void) {
        encodeInterchange(encoder: JSONInterchangeEncoder()) { dictionary in
            if let data = try? JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted]), let json = String(data: data, encoding: .utf8) {
                completion(json)
            } else {
                completion("[]")
            }
        }
    }
}
