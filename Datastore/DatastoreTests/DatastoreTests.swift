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
                let person = people[0]
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
                
                let context = datastore.container.viewContext
                let label = Symbol.named("foo", in: context)
                person.add(property: label, value: "bar")
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
    
    func testAddProperties() {
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.getEntities(ofType: "Person", names: ["Person 1"]) { (people) in
                let person = people[0]
                datastore.add(properties: [person:["foo": "bar"]]) { () in
                    datastore.getProperties(ofEntities: [person], withNames: ["foo"]) { (results) in
                        XCTAssertEqual(results.count, 1)
                        let properties = results[0]
                        XCTAssertEqual(properties["foo"] as? String, "bar")
                        done.fulfill()
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }
    
    func testReadJSON() {
        let json = """
            {
              "entities" : [
                {
                  "created" : {
                    "date" : "2019-09-17T16:10:38Z"
                  },
                  "name" : "Person 1",
                  "uuid" : "C41DB873-323D-4026-95D1-603120B9ADF6",
                  "modified" : {
                    "date" : "2019-09-17T16:10:38Z"
                  },
                  "type" : "F9B7D73D-2020-49AD-B85D-4BBD62CCA80B",
                  "foo" : "bar"
                },
                {
                  "created" : {
                    "date" : "2019-09-17T16:10:38Z"
                  },
                  "uuid" : "ADDD557A-668E-4C6B-A9A0-3BCF099646E8",
                  "modified" : {
                    "date" : "2019-09-17T16:10:38Z"
                  },
                  "name" : "Person 2",
                  "type" : "F9B7D73D-2020-49AD-B85D-4BBD62CCA80B",
                  "foo" : "baz"
                }
              ],
              "symbols" : [
                {
                  "name" : "foo",
                  "uuid" : "078D9906-F26D-4028-99E6-880B32398C37"
                },
                {
                  "uuid" : "F9B7D73D-2020-49AD-B85D-4BBD62CCA80B",
                  "name" : "Person"
                }
              ]
            }
            """
        
        let loaded = expectation(description: "loaded")
        Datastore.load(name: "Test", json: json) { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
                
            case .success(let store):
                let expected = ["Person 1": "bar", "Person 2": "baz"]
                store.getAllEntities(ofType: "Person") { (people) in
                    XCTAssertEqual(people.count, 2)
                    store.getProperties(ofEntities: people, withNames: ["foo"]) { results in
                        var n = 0
                        for person in people {
                            let name = person.name!
                            let properties = results[n]
                            let value = properties["foo"] as? String
                            let expectedValue = expected[name]
                            n += 1
                            XCTAssertEqual(expectedValue, value, "\(name)")
                        }
                        loaded.fulfill()
                        
                    }
                }
            }
        }
        wait(for: [loaded], timeout: 1.0)
    }
    
    //    func testInterchange() {
    //        let done = expectation(description: "loaded")
    //        loadAndCheck { (datastore) in
    //            let names = Set<String>(["Person 1", "Person 2"])
    //            datastore.getEntities(ofType: "Person", names: names) { (people) in
    //                let person = people[0]
    //                datastore.add(properties: [person:["foo": "bar"]]) { () in
    //                    datastore.interchange() { interchange in
    //                        for (key, value) in interchange {
    //                            XCTAssertEqual(key, "Person")
    //                            if let entities = value as? [[String:Any]] {
    //                                for entity in entities {
    //                                    XCTAssertTrue(names.contains(entity["name"] as! String))
    //                                }
    //                            }
    //                        }
    //
    //                        done.fulfill()
    //                    }
    //                }
    //            }
    //        }
    //        wait(for: [done], timeout: 1.0)
    //    }
    
    func testInterchangeJSON() {
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            let names = Set<String>(["Person 1", "Person 2"])
            datastore.getEntities(ofType: "Person", names: names) { (people) in
                let person = people[0]
                datastore.add(properties: [person:["foo": "bar"]]) { () in
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
