//
//  DatastoreTests.swift
//  DatastoreTests
//
//  Created by Developer on 16/09/2019.
//  Copyright © 2019 Developer. All rights reserved.
//

import XCTest
import Combine

@testable import Datastore

class DatastoreTests: XCTestCase {
    
    func loadAndCheck(completion: @escaping (Datastore) -> Void) {
        Datastore.load(name: "Test") { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
                
            case .success(let store):
                completion(store)
            }
        }
    }
    
    func loadJSON(name: String, expectation: XCTestExpectation, completion: @escaping (Datastore) -> Void) {
        let url = Bundle(for: type(of: self)).url(forResource: name, withExtension: "json")!
        let json = String(data: try! Data(contentsOf: url), encoding: .utf8)!
        Datastore.load(name: name, json: json) { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
                expectation.fulfill()
                
            case .success(let store):
                completion(store)
            }
        }
    }
    
    func check<Output, Failure>(action: String, future: Future<Output, Failure>) {
        let done = expectation(description: action)
        let _ = future.sink(
            receiveCompletion: { (completion) in
                switch completion {
                case .failure(let error):
                    XCTFail("\(action) error: \(error)")
                case .finished:
                    break
                }
                done.fulfill()
        }, receiveValue: { (store) in
        })
        wait(for: [done], timeout: 1.0)
    }
    
    func testCreation() {
        let loaded = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 1.0)
    }
    
    func testEntityCreation() {
        let created = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.get(entities: ["Person 1"], ofType: "Person") { (people) in
                XCTAssertEqual(people.count, 1)
                let person = people[0].object
                XCTAssertEqual(person.string(withKey: datastore.standardSymbols.name), "Person 1")
                created.fulfill()
            }
        }
        wait(for: [created], timeout: 1.0)
    }
    
    func testGetProperties() {
        let done = expectation(description: "done")
        loadJSON(name: "Simple", expectation: done) { datastore in
            datastore.get(allEntitiesOfType: "person") { (people) in
                datastore.get(properties : ["foo"], of: people) { (results) in
                    XCTAssertEqual(results.count, 1)
                    let properties = results[0]
                    XCTAssertEqual(properties["foo"] as? String, "bar")
                }
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetAllProperties() {
        let done = expectation(description: "done")
        loadJSON(name: "Simple", expectation: done) { datastore in
            datastore.get(allEntitiesOfType: "person") { (people) in
                datastore.get(allPropertiesOf: people) { (results) in
                    XCTAssertEqual(results.count, 1)
                    let properties = results[0]
                    XCTAssertEqual(properties["foo"] as? String, "bar")
                }
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func exampleProperties(date: Date = Date(), owner: EntityID, in store: Datastore) -> SemanticDictionary {
        var properties = SemanticDictionary()
        properties["address"] = store.value("123 New St", type: "address")
        properties["date"] = date
        properties["integer"] = 123
        properties["double"] = 456.789
        properties["owner"] = (owner, "owner")
        return properties
    }
    
    func testAddProperties() {
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.get(entities: ["Person 1"], ofType: "Person") { (people) in
                let person = people[0]
                let now = Date()
                datastore.add(properties: [person: self.exampleProperties(date: now, owner: person, in: datastore)]) { () in
                    datastore.get(properties : ["address", "date", "integer", "double", "owner"], of: [person]) { (results) in
                        XCTAssertEqual(results.count, 1)
                        let properties = results[0]
                        XCTAssertEqual(properties["address"] as? String, "123 New St")
                        XCTAssertEqual(properties["date"] as? Date, now)
                        XCTAssertEqual(properties["integer"] as? Int64, 123)
                        XCTAssertEqual(properties["double"] as? Double, 456.789)
                        XCTAssertEqual(properties["owner"] as? Entity, person)
                        done.fulfill()
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }
    
    
    func testCompactJSON() {
        testReadJSON(name: "Compact", checkAddressType: false)
    }
    
    func testNormalizedJSON() {
        testReadJSON(name: "Normalized", checkAddressType: true)
    }
    
    func testReadJSON(name: String, checkAddressType: Bool) {
        let loaded = expectation(description: "loaded")
        loadJSON(name: name, expectation: loaded) { store in
            let expected = ["Person 1": "123 New St", "Person 2": "456 Old St"]
            store.get(allEntitiesOfType: "person") { (people) in
                XCTAssertEqual(people.count, 2)
                store.get(properties : ["name", "address", "datestamp", "modified", "owner"], of: people) { results in
                    var n = 0
                    for result in results {
                        let name = result["name"] as! String
                        XCTAssertEqual(result[typeNameWithKey: "name", store], "string")
                        let value = result["address"] as! String
                        if checkAddressType {
                            XCTAssertEqual(result[typeNameWithKey: "address", store], "address")
                        }
                        let expectedValue = expected[name]
                        XCTAssertEqual(expectedValue, value, "\(name)")
                        let created = result["datestamp"] as! Date
                        XCTAssertEqual(created.description, "1969-11-12 01:23:45 +0000")
                        XCTAssertEqual(result[typeNameWithKey: "datestamp", store], "date")
                        let modified = result["modified"] as! Date
                        XCTAssertEqual(modified.description, "1963-09-21 01:23:45 +0000")
                        XCTAssertEqual(result[typeNameWithKey: "modified", store], "date")
                        let owner = result["owner"] as! Entity
                        XCTAssertEqual(owner, people[n])
                        XCTAssertEqual(result[typeNameWithKey: "owner", store], "owner")
                        n += 1
                    }
                    loaded.fulfill()
                }
            }
        }
        wait(for: [loaded], timeout: 1.0)
    }
    
    func testInterchange() {
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            let names = Set<String>(["Person 1", "Person 2"])
            datastore.get(entities: names, ofType: "Person") { (people) in
                let person = people[0]
                datastore.add(properties: [person: self.exampleProperties(owner: people[1], in: datastore)]) { () in
                    datastore.encodeInterchange() { interchange in
                        if let entities = interchange["entities"] as? [[String:Any]] {
                            for entity in entities {
                                let nameRecord = entity["name"] as? [String:Any]
                                XCTAssertTrue(names.contains(nameRecord?["string"] as! String))
                            }
                        }
                        
                        done.fulfill()
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }
    
    func testInterchangeJSON() {
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            let names = Set<String>(["Person 1", "Person 2"])
            datastore.get(entities: names, ofType: "Person") { (people) in
                let person = people[0]
                datastore.add(properties: [person: self.exampleProperties(owner: people[1], in: datastore)]) { () in
                    datastore.encodeJSON() { json in
                        print(json)
                        done.fulfill()
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testLoadFuture() {
        let future = Datastore.loadCombine(name: "test")
        check(action: "load", future: future)
    }
    
    func testChangeName() {
        let created = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.get(entities: ["Person 1"], ofType: "Person") { (people) in
                let person = people[0]
                var properties = SemanticDictionary()
                properties["name"] = "New Name"
                datastore.add(properties: [person : properties]) {
                    XCTAssertEqual(people.count, 1)
                    XCTAssertEqual(person.object.string(withKey: datastore.standardSymbols.name), "New Name")
                    created.fulfill()
                }
            }
        }
        wait(for: [created], timeout: 1.0)
    }
    
    func testGetPropertyReturnsNewest() {
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.get(entities: ["test"], ofType: "test") { (entities) in
                XCTAssertEqual(entities.count, 1)
                let entity = entities[0]
                var properties = SemanticDictionary()
                properties["thing"] = "foo"
                datastore.add(properties: [entity: properties]) { () in
                    properties["thing"] = "bar"
                    datastore.add(properties: [entity: properties]) { () in
                        datastore.get(properties : ["thing"], of: [entity]) { (results) in
                            XCTAssertEqual(results.count, 1)
                            let properties = results[0]
                            XCTAssertEqual(properties["thing"] as? String, "bar")
                            done.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }
    
    func testDeletion() {
        let done = expectation(description: "done")
        loadJSON(name: "Deletion", expectation: done) { store in
            store.get(entities: ["Test1"], ofType: "test") { (entities) in
                store.get(properties: ["foo", "bar"], of: entities) { before in
                    let properties = before[0]
                    XCTAssertNotNil(properties["foo"])
                    XCTAssertNotNil(properties["bar"])
                    store.remove(properties: ["foo"], of: entities) {
                        store.get(properties: ["foo", "bar"], of: entities) { after in
                            let properties = after[0]
                            XCTAssertNil(properties["foo"])
                            XCTAssertNotNil(properties["bar"])
                            done.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }
}
