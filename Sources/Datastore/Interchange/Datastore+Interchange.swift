// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import Logger

let InterchangeChannel = Channel("com.elegantchaos.datastore.Interchange")


public struct Profiler { // TODO: move this to a different package
    let start = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
    
    var elapsedNanoseconds: UInt {
        let finish = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        return UInt(finish - start)
    }
    
    var elapsed: Double {
        let finish = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        return Double(finish - start) / 1000000000.0
    }
}


extension Datastore {
    
    public func decode(json: String, completion: @escaping (LoadResult) -> Void) {
        let jsonTimer = Profiler()
        guard let data = json.data(using: .utf8) else {
            completion(.failure(InvalidJSONError()))
            return
        }
        
        do {
            if let interchange = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
                InterchangeChannel.log("Converted JSON in \(jsonTimer.elapsed) seconds.")
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
        save() { result in
            switch result {
                case .success():
                    completion(.success(self))

                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }

 
    fileprivate func decodeEntities(from interchange: [String : Any], with decoder: InterchangeDecoder) {
        let context = self.context
        context.perform {
            let decodeTimer = Profiler()
            let startCount = context.countEntities(type: EntityRecord.self)

            self.suspendNotifications()
            self.startCaching()

            if let entities = interchange[PropertyKey.entities.value] as? [[String:Any]] {
                // first pass, fill the cache, making any missing entities
                for entityInterchange in entities {
                    if let identifier = entityInterchange[PropertyKey.identifier.value] as? String {
                        var entity = self.getCached(identifier: identifier) ?? (startCount > 0 ? EntityRecord.withIdentifier(identifier, in: context) : nil)
                        if entity == nil, let type = entityInterchange[PropertyKey.type.value] as? String {
                            let newEntity = EntityRecord(in: context)
                            newEntity.identifier = identifier
                            newEntity.type = type
                            entity = newEntity
                            self.addCached(identifier: identifier, entity: newEntity)
                        }
                    }
                }

                // second pass, decode properties
                for entityInterchange in entities {
                    if let identifier = entityInterchange[PropertyKey.identifier.value] as? String {
                        if let entity = self.getCached(identifier: identifier) {
                            self.decodeEntity(entity, with: decoder, values: entityInterchange)
                        }
                    }
                }
            }

            let finishCount = context.countEntities(type: EntityRecord.self)
            InterchangeChannel.log("Decoded \(finishCount - startCount) entities in \(decodeTimer.elapsed) seconds.")
            if let cache = self.entityCache {
                InterchangeChannel.log("\(cache.cacheHits) hits, \(cache.cacheMisses) misses, \(cache.cacheRewrites) rewrites.")
            }
            
            self.stopCaching()
            self.resumeNotifications()
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
