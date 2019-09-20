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
            datastore.getEntities(ofType: "Person", names: ["Person 1"]) { (people) in
                XCTAssertEqual(people.count, 1)
                let person = people[0].object
                XCTAssertEqual(person.name, "Person 1")
                created.fulfill()
            }
        }
        wait(for: [created], timeout: 1.0)
    }
    
    func testGetProperties() {
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.getEntities(ofType: "Person", names: ["Person 1"]) { (people) in
                let person = people[0]
                
                let context = datastore.context
                let label = SymbolRecord.named("foo", in: context)
                person.object.add(property: label, value: datastore.value("bar"), store: datastore)
                datastore.getProperties(ofEntities: [person], withNames: ["foo"]) { (results) in
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
        properties["number"] = 123 // store.value(123)
        properties["owner"] = store.value(owner, type: "owner")
        return properties
    }
    
    func testAddProperties() {
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.getEntities(ofType: "Person", names: ["Person 1"]) { (people) in
                let person = people[0]
                let now = Date()
                datastore.add(properties: [person: self.exampleProperties(date: now, owner: person, in: datastore)]) { () in
                    datastore.getProperties(ofEntities: [person], withNames: ["address", "date", "number"]) { (results) in
                        XCTAssertEqual(results.count, 1)
                        let properties = results[0]
                        XCTAssertEqual(properties["address"] as? String, "123 New St")
                        XCTAssertEqual(properties["date"] as? Date, now)
                        XCTAssertEqual(properties["number"] as? Int64, 123)
                        done.fulfill()
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }
    

    func testCompactJSON() {
        let json = """
            {
              "entities" : [
                {
                  "name" : "Person 1",
                  "uuid" : "C41DB873-323D-4026-95D1-603120B9ADF6",
                  "created" : { "date" : "1969-11-12T01:23:45Z" },
                  "modified" : { "date" : "1963-09-21T01:23:45Z" },
                  "type" : "F9B7D73D-2020-49AD-B85D-4BBD62CCA80B",
                  "address" : "123 New St"
                },
                {
                  "name" : "Person 2",
                  "uuid" : "ADDD557A-668E-4C6B-A9A0-3BCF099646E8",
                  "created" : { "date" : "1969-11-12T01:23:45Z" },
                  "modified" : { "date" : "1963-09-21T01:23:45Z" },
                  "type" : "F9B7D73D-2020-49AD-B85D-4BBD62CCA80B",
                  "address" : "456 Old St"
                }
              ],
              "symbols" : [
                {
                  "name" : "foo",
                  "uuid" : "078D9906-F26D-4028-99E6-880B32398C37"
                },
                {
                  "uuid" : "F9B7D73D-2020-49AD-B85D-4BBD62CCA80B",
                  "name" : "person"
                }
              ]
            }
            """

        testReadJSON(json: json)
    }
    
    func testNormalizedJSON() {
        let json = """
            {
              "entities" : [
                {
                  "uuid" : "FE396F3F-A325-4F50-899C-F22308C97D12",
                  "type" : "09035403-D3AE-4076-A77C-0B5596E5E361",
                  "name" : "Person 1",
                  "created" : { "date" : "1969-11-12T01:23:45Z" },
                  "modified" : { "date" : "1963-09-21T01:23:45Z" },
                  "address" : {
                      "string" : "123 New St",
                      "type" : "93E59849-0410-4390-AAE0-197FD3878223"
                    },
                },

                {
                  "address" : {
                    "string" : "456 Old St",
                    "type" : "93E59849-0410-4390-AAE0-197FD3878223"
                  },
                  "owner" : {
                    "entity" : "FE396F3F-A325-4F50-899C-F22308C97D12",
                    "type" : "B9B994A8-B47E-4EF2-9440-0E7564CA5C6A"
                  },
                  "created" : { "date" : "1969-11-12T01:23:45Z" },
                  "modified" : { "date" : "1963-09-21T01:23:45Z" },
                  "date" : {
                    "date" : "2019-09-19T16:14:58Z",
                    "type" : "C85E45D1-4F00-4A63-A2C9-0F8E2475A1DB"
                  },
                  "type" : "09035403-D3AE-4076-A77C-0B5596E5E361",
                  "uuid" : "652A3D31-C409-4CBE-8469-6232D1EEBC96",
                  "number" : {
                    "integer" : 123,
                    "type" : "C85E45D1-4F00-4A63-A2C9-0F8E2475A1DB"
                  },
                  "name" : "Person 2"
                }
              ],
              "symbols" : [
                {
                  "uuid" : "B9B994A8-B47E-4EF2-9440-0E7564CA5C6A",
                  "name" : "owner"
                },
                {
                  "name" : "null",
                  "uuid" : "C85E45D1-4F00-4A63-A2C9-0F8E2475A1DB"
                },
                {
                  "uuid" : "0D39C199-65BF-417F-BA22-077E1023A766",
                  "name" : "number"
                },
                {
                  "uuid" : "09035403-D3AE-4076-A77C-0B5596E5E361",
                  "name" : "person"
                },
                {
                  "name" : "address",
                  "uuid" : "93E59849-0410-4390-AAE0-197FD3878223"
                },
                {
                  "name" : "date",
                  "uuid" : "A697927C-2986-496A-815F-64120A5B2521"
                }
              ]
            }
            """

        testReadJSON(json: json)
    }
    
    func testReadJSON(json: String) {
        
        let loaded = expectation(description: "loaded")
        Datastore.load(name: "Test", json: json) { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
                
            case .success(let store):
                let expected = ["Person 1": "123 New St", "Person 2": "456 Old St"]
                store.getAllEntities(ofType: "person") { (people) in
                    XCTAssertEqual(people.count, 2)
                    store.getProperties(ofEntities: people, withNames: ["name", "address", "created", "modified"]) { results in
                        for result in results {
                            let name = result["name"] as! String
                            let value = result["address"] as! String
                            let expectedValue = expected[name]
                            XCTAssertEqual(expectedValue, value, "\(name)")
                            let created = result["created"] as! Date
                            XCTAssertEqual(created.description, "1969-11-12 01:23:45 +0000")
                            let modified = result["modified"] as! Date
                            XCTAssertEqual(modified.description, "1963-09-21 01:23:45 +0000")
                        }
                        loaded.fulfill()
                        
                    }
                }
            }
        }
        wait(for: [loaded], timeout: 1.0)
    }
    
        func testInterchange() {
            let done = expectation(description: "loaded")
            loadAndCheck { (datastore) in
                let names = Set<String>(["Person 1", "Person 2"])
                datastore.getEntities(ofType: "Person", names: names) { (people) in
                    let person = people[0]
                    datastore.add(properties: [person: self.exampleProperties(owner: people[1], in: datastore)]) { () in
                        datastore.encodeInterchange() { interchange in
                            if let entities = interchange["entities"] as? [[String:Any]] {
                                for entity in entities {
                                    XCTAssertTrue(names.contains(entity["name"] as! String))
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
            datastore.getEntities(ofType: "Person", names: names) { (people) in
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
    
    func testLoadFuture() {
        let future = Datastore.loadCombine(name: "test")
        check(action: "load", future: future)
    }
}
