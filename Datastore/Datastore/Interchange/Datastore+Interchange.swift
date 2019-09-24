// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Developer on 17/09/2019.
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
        let symbols = decodeSymbols(from: interchange, decoder: decoder)
        decodeEntities(from: interchange, with: decoder, symbols: symbols)
        try? context.save()
        completion(.success(self))
    }
    
    fileprivate func decodeSymbols(from interchange: [String : Any], decoder: InterchangeDecoder) -> [UUID:SymbolRecord] {
        var symbolIndex: [UUID:SymbolRecord] = [:]
        if let symbols = interchange["symbols"] as? [[String:Any]] {
            for symbolRecord in symbols {
                if let uuid = decoder.decodePrimitive(uuid: symbolRecord["uuid"]), let name = symbolRecord["name"] as? String {
                    let symbol = SymbolID(uuid: uuid, name: name)
                    symbolIndex[uuid] = symbol.resolve(in: context)
                }
            }
        }
        return symbolIndex
    }
    
 
    fileprivate func decodeEntities(from interchange: [String : Any], with decoder: InterchangeDecoder, symbols symbolIndex: [UUID : SymbolRecord]) {
        if let entities = interchange["entities"] as? [[String:Any]] {
            for entityRecord in entities {
                if let name = entityRecord["name"] as? String, let uuid = decoder.decodePrimitive(uuid: entityRecord["uuid"]), let type = decoder.decodePrimitive(uuid: entityRecord["type"]) {
                    var entity = EntityRecord.withIdentifier(uuid, in: context)
                    if entity == nil {
                        let newEntity = EntityRecord(in: context)
                        newEntity.uuid = uuid
                        newEntity.type = symbolIndex[type]
                        entity = newEntity
                        try? context.save()
                    }
                    if let entity = entity {
                        decodeEntity(entity, name: name, with: decoder, values: entityRecord)
                    }
                }
            }
        }
    }
    
    fileprivate func decodeEntity(_ entity: EntityRecord, name: String, with decoder: InterchangeDecoder, values entityRecord: [String : Any]) {
         entity.datestamp = decoder.decode(entityRecord["datestamp"], store: self).coerced(or: Date())
         var entityProperties = entityRecord
         for key in Datastore.specialProperties {
             entityProperties.removeValue(forKey: key)
         }
        decode(properties: entityProperties, of: entity, with: decoder)
     }
     
    fileprivate func decode(properties: [String:Any], of entity: EntityRecord, with decoder: InterchangeDecoder) {
        for (key, value) in properties {
            entity.add(property: SymbolID(named: key), value: decoder.decode(value, store: self), store: self)
        }
    }

    public func encodeInterchange(encoder: InterchangeEncoder = NullInterchangeEncoder(), completion: @escaping InterchangeCompletion) {
        let context = self.context
        context.perform {
            var symbolResults: [[String:Any]] = []
            var entityResults: [[String:Any]] = []
            let request: NSFetchRequest<SymbolRecord> = SymbolRecord.fetcher(in: context)
            if let symbols = try? context.fetch(request) {
                for symbol in symbols {
                    var record: [String:Any] = [:]
                    let type = encoder.encodePrimitive(symbol.uuid)
                    record["name"] = symbol.name
                    record["uuid"] = type
                    symbolResults.append(record)
                    
                    if let entities = symbol.entities as? Set<EntityRecord> {
                        for entity in entities {
                            var record: [String:Any] = [:]
                            record["type"] = type
                            record["datestamp"] = encoder.encodePrimitive(entity.datestamp)
                            record["uuid"] = encoder.encodePrimitive(entity.uuid)
                            entity.encode(from: entity.strings, as: StringProperty.self, into: &record, encoder: encoder)
                            entity.encode(from: entity.integers, as: IntegerProperty.self, into: &record, encoder: encoder)
                            entity.encode(from: entity.dates, as: DateProperty.self, into: &record, encoder: encoder)
                            entity.encode(from: entity.relationships, as: RelationshipProperty.self, into: &record, encoder: encoder)
                            entityResults.append(record)
                        }
                    }
                }
                let result = [
                    "symbols" : symbolResults,
                    "entities" : entityResults
                ]
                completion(result)
            }
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