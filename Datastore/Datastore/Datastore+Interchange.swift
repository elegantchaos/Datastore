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
        let context = self.context
        var symbolIndex: [String:SymbolRecord] = [:]
        if let symbols = interchange["symbols"] as? [[String:Any]] {
            for symbolRecord in symbols {
                if let uuid = symbolRecord["uuid"] as? String, let name = symbolRecord["name"] as? String {
                    let symbol = self.symbol(uuid: uuid, name: name)
                    symbolIndex[uuid] = symbol
                }
            }
        }
        
        if let entities = interchange["entities"] as? [[String:Any]] {
            for entityRecord in entities {
                if let name = entityRecord["name"] as? String, let uuid = entityRecord["uuid"] as? String, let type = entityRecord["type"] as? String {
                    var entity = EntityRecord.withIdentifier(uuid, in: context)
                    if entity == nil {
                        let newEntity = EntityRecord(in: context)
                        newEntity.uuid = UUID(uuidString: uuid)
                        newEntity.type = symbolIndex[type]
                        entity = newEntity
                        print("made \(name)")
                    }
                    if let entity = entity {
                        entity.name = name
                        entity.created = decoder.decode(value: entityRecord["created"], default: Date())
                        entity.modified = decoder.decode(value: entityRecord["modified"], default: Date())
                        var entityProperties = entityRecord
                        for key in Datastore.specialProperties {
                            entityProperties.removeValue(forKey: key)
                        }
                        print("adding \(entityProperties)")
                        entity.add(properties: entityProperties, store: self)
                    }
                }
            }
        }
        
        try? context.save()
        completion(.success(self))
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
                    let type = encoder.encode(symbol.uuid)
                    record["name"] = symbol.name
                    record["uuid"] = type
                    symbolResults.append(record)
                    
                    if let entities = symbol.entities as? Set<EntityRecord> {
                        for entity in entities {
                            var record: [String:Any] = [:]
                            record["name"] = entity.name
                            record["type"] = type
                            record["created"] = encoder.encode(entity.created)
                            record["modified"] = encoder.encode(entity.modified)
                            record["uuid"] = entity.uuid!.uuidString
                            entity.encode(from: entity.strings, as: StringPropertyRecord.self, into: &record, encoder: encoder)
                            entity.encode(from: entity.integers, as: IntegerPropertyRecord.self, into: &record, encoder: encoder)
                            entity.encode(from: entity.dates, as: DatePropertyRecord.self, into: &record, encoder: encoder)
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
