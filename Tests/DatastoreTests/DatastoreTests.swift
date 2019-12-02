// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import XCTestExtensions

@testable import Datastore

extension EntityType {
    static let person: Self = "person"
    static let test: Self = "test"
}

class DatastoreTests: DatastoreTestCase {
    fileprivate func checkInterchangeDictionary(_ interchange: [String : Any], names: Set<String>) {
         if let entities = interchange["entities"] as? [[String:Any]] {
             for entity in entities {
                 let nameRecord = entity["name"] as? [String:Any]
                 XCTAssertTrue(names.contains(nameRecord?["string"] as! String))
             }
         }
     }
     
     fileprivate func checkJSON(name: String, checkAddressType: Bool) {
         // read and check some JSON
         let loaded = expectation(description: "loaded")
         loadJSON(name: name, expectation: loaded) { store in
             let expected = ["Person 1": "123 New St", "Person 2": "456 Old St"]
             store.get(allEntitiesOfType: .test) { (people) in
                 XCTAssertEqual(people.count, 2)
                 store.get(properties : ["name", "address", "datestamp", "modified", "owner", "data"], of: people) { results in
                     var n = 0
                     for result in results {
                         let name = result["name"] as! String
                         XCTAssertEqual(result[typeWithKey: "name"], "string")
                         let value = result["address"] as! String
                         if checkAddressType {
                             XCTAssertEqual(result[typeWithKey: "address"], "address")
                         }
                         let data = result["data"] as! Data
                         XCTAssertEqual(String(data: data, encoding: .utf8), "encoded string")
                         XCTAssertEqual(result[typeWithKey: "data"], "data")
                         let expectedValue = expected[name]
                         XCTAssertEqual(expectedValue, value, "\(name)")
                         let created = result["datestamp"] as! Date
                         XCTAssertEqual(created.description, "1969-11-12 01:23:45 +0000")
                         XCTAssertEqual(result[typeWithKey: "datestamp"], "date")
                         let modified = result["modified"] as! Date
                         XCTAssertEqual(modified.description, "1963-09-21 01:23:45 +0000")
                         XCTAssertEqual(result[typeWithKey: "modified"], "date")
                         let owner = result["owner"] as! GuaranteedReference
                         XCTAssertEqual(owner, people[n])
                         XCTAssertEqual(result[typeWithKey: "owner"], "owner")
                         n += 1
                     }
                     loaded.fulfill()
                 }
             }
         }
         wait(for: [loaded], timeout: 1.0)
     }
    
    func testCreation() {
        let loaded = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 1.0)
    }
    
    
    func testLoadFromFile() {
        // set the REBUILD_TEST_FILE environment variable to recreate the test sqlite database from Test.json
        // (eg: `export REBUILD_TEST_FILE=1; swift test`)
        if testFlag("REBUILD_TEST_FILE") {
            createTestFile()
            XCTFail("rebuilt test file; run again without REBUILD_TEST_FILE to run the actual test")
        } else {
            let url = testURL(named: "Test", withExtension: "sqlite")
            let loaded = expectation(description: "loaded")
            loadAndCheck(url: url) { store in
                store.get(allEntitiesOfType: .person) { (people) in
                    XCTAssertEqual(people.count, 1)
                    store.get(properties: ["name", "age"], of: people) { results in
                        let properties = results[0]
                        XCTAssertEqual(properties["name"] as? String, "Test")
                        XCTAssertEqual(properties["age"] as? Int, 21)
                        loaded.fulfill()
                    }
                }
            }
            wait(for: [loaded], timeout: 1.0)
        }
    }
    
    func testEntityCreation() {
        // create an entity via `get:where:` and check that the name has been set correctly
        let created = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.get(entityOfType: .person, where: "name", equals: "Person 1") { person in
                XCTAssertEqual(person?.object.string(withKey: .name), "Person 1")
                created.fulfill()
            }
        }
        wait(for: [created], timeout: 1.0)
    }
    
    func testGetEntityByIdentifier() {
        // test looking up an entity of a given type by id
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityID = Entity.identifiedBy("C41DB873-323D-4026-95D1-603120B9ADF6")
            datastore.get(entitiesOfType: .person, withIDs: [entityID]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.object.string(withKey: .name), "Test")
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByIdentifierMissing() {
        // test looking up an entity of of a given type by id when it doesn't exist
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityID = Entity.identifiedBy("unknown-id")
            datastore.get(entitiesOfType: .person, withIDs: [entityID]) { results in
                XCTAssertEqual(results.count, 0)
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByIdentifierWrongType() {
        // test looking up an entity of a given type by id when it exists but is a different type
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityID = Entity.identifiedBy("C41DB873-323D-4026-95D1-603120B9ADF6")
            datastore.get(entitiesOfType: .test, withIDs: [entityID]) { results in
                XCTAssertEqual(results.count, 0)
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByIdentifierCreateWhenMissing() {
        // test looking up an entity by id and creating it because it didn't exist
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let missingID = Entity.identifiedBy("no-such-id", createAs: .person)
            datastore.get(entitiesOfType: .person, withIDs: [missingID]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.identifier, "no-such-id")
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByName() {
        // test looking up an entity by name
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityRef = Entity.named("Test")
            datastore.get(entitiesOfType: .person, withIDs: [entityRef]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.identifier, "C41DB873-323D-4026-95D1-603120B9ADF6")
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByNameFail() {
        // test looking up an entity by name when it doesn't exist
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityRef = Entity.named("Unknown")
            datastore.get(entitiesOfType: .person, withIDs: [entityRef]) { results in
                XCTAssertEqual(results.count, 0)
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByNameCreateWhenMissingWithFixedIdentifier() {
        // test looking up an entity by name when it doesn't exist
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityRef = Entity.named("Unknown", initialiser: EntityInitialiser(as: .person, properties:["foo": "bar"], identifier: "known-identifier"))
            datastore.get(entitiesOfType: .person, withIDs: [entityRef]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.identifier, "known-identifier")
                XCTAssertEqual(person.object.string(withKey: .name), "Unknown")
                XCTAssertEqual(person.object.string(withKey: "foo"), "bar")
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByKey() {
        // test looking up an entity by an arbitrary property
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityRef = Entity.whereKey("foo", equals: "bar")
            datastore.get(entitiesOfType: .person, withIDs: [entityRef]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.identifier, "C41DB873-323D-4026-95D1-603120B9ADF6")
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByKeyFail() {
        // test looking up an entity by an arbitrary property when it doesn't exist
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityRef = Entity.whereKey("foo", equals: "unknown")
            datastore.get(entitiesOfType: .person, withIDs: [entityRef]) { results in
                XCTAssertEqual(results.count, 0)
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }
    
    func testGetEntityByIdentifierOrNameMatchingID() {
        // test looking up an entity of a given type by id
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityID = Entity.with(identifier: "C41DB873-323D-4026-95D1-603120B9ADF6", orName: "Test")
            datastore.get(entitiesOfType: .person, withIDs: [entityID]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.identifier, "C41DB873-323D-4026-95D1-603120B9ADF6")
                XCTAssertEqual(person.object.string(withKey: .name), "Test")
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByIdentifierOrNameMatchingName() {
        // test looking up an entity of a given type by id
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityID = Entity.with(identifier: "another-id", orName: "Test")
            datastore.get(entitiesOfType: .person, withIDs: [entityID]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.identifier, "C41DB873-323D-4026-95D1-603120B9ADF6")
                XCTAssertEqual(person.object.string(withKey: .name), "Test")
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityByIdentifierOrNameMissing() {
        // test looking up an entity of a given type by id
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let entityID = Entity.with(identifier: "missing-id", orName: "Missing Name", createAs: .person)
            datastore.get(entitiesOfType: .person, withIDs: [entityID]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.identifier, "missing-id")
                XCTAssertEqual(person.object.string(withKey: .name), "Missing Name")
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityCreateWithInitialProperties() {
        // test looking up an entity by id, and creating it with some initial properties when it doesn't exist
        let done = expectation(description: "loaded")
        loadAndCheck { datastore in
            let missingID = Entity.identifiedBy("no-such-id", initialiser: EntityInitialiser(as: .person, properties: [.name: "Test"]))
            datastore.get(entitiesOfType: .person, withIDs: [missingID]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.identifier, "no-such-id")
                XCTAssertEqual(person.object.string(withKey: .name), "Test") // new name should not have been applied since the entity already exists
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetEntityInitialPropertiesIgnoredIfAlreadyExists() {
        // test looking up an entity by id, passing some initial properties for when it doesn't exist, but
        // not having the properties applied because the entity already existed
        let done = expectation(description: "loaded")
        loadJSON(name: "Simple", expectation: done) { datastore in
            let id = Entity.identifiedBy("C41DB873-323D-4026-95D1-603120B9ADF6", initialiser: EntityInitialiser(as: .person, properties: [.name: "Different Name"]))
            datastore.get(entitiesOfType: .person, withIDs: [id]) { results in
                XCTAssertEqual(results.count, 1)
                let person = results[0]
                XCTAssertEqual(person.object.string(withKey: .name), "Test") // new name should not have been applied since the entity already exists
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }
    
    func testGetProperties() {
        // test getting some properties of an existing entity
        let done = expectation(description: "done")
        loadJSON(name: "Simple", expectation: done) { datastore in
            datastore.get(allEntitiesOfType: .person) { (people) in
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

    func testGetUnknownProperties() {
        // test getting some non-existent properties of an existing entity
        let done = expectation(description: "done")
        loadJSON(name: "Simple", expectation: done) { datastore in
            datastore.get(allEntitiesOfType: .person) { (people) in
                datastore.get(properties : ["non-existent-property"], of: people) { (results) in
                    XCTAssertEqual(results.count, 1)
                    let properties = results[0]
                    XCTAssertEqual(properties.count, 0)
                }
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testGetAllProperties() {
        // test getting all properties of an existing entity
        let done = expectation(description: "done")
        loadJSON(name: "Simple", expectation: done) { datastore in
            datastore.get(allEntitiesOfType: .person) { (people) in
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
    
    func testAddProperties() {
        // test adding properties to an existing entity
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.get(entityOfType: .person, where: "name", equals: "Person 1") { person in
                guard let person = person else {
                    XCTFail("missing person")
                    done.fulfill()
                    return
                }
                
                let now = Date()
                datastore.add(properties: [person: self.exampleProperties(date: now, owner: person, in: datastore)]) { () in
                    datastore.get(properties : ["address", "date", "integer", "double", "owner"], of: [person]) { (results) in
                        XCTAssertEqual(results.count, 1)
                        let properties = results[0]
                        XCTAssertEqual(properties["address"] as? String, "123 New St")
                        XCTAssertEqual(properties["date"] as? Date, now)
                        XCTAssertEqual(properties["integer"] as? Int, 123)
                        XCTAssertEqual(properties["double"] as? Double, 456.789)
                        XCTAssertEqual(properties["owner"] as? GuaranteedReference, person)
                        done.fulfill()
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    func testCreateAndAddProperties() {
        // test adding properties to an existing entity
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            let person = Entity.named("Somebody New", createAs: .person)
            let now = Date()
            datastore.add(properties: [person: self.exampleProperties(date: now, owner: person, in: datastore)]) { () in
                datastore.get(properties : ["name", "address", "date", "integer", "double", "owner"], of: [person]) { (results) in
                    XCTAssertEqual(results.count, 1)
                    let properties = results[0]
                    XCTAssertEqual(properties["name"] as? String, "Somebody New")
                    XCTAssertEqual(properties["address"] as? String, "123 New St")
                    XCTAssertEqual(properties["date"] as? Date, now)
                    XCTAssertEqual(properties["integer"] as? Int, 123)
                    XCTAssertEqual(properties["double"] as? Double, 456.789)
                    XCTAssertEqual(properties["owner"] as? GuaranteedReference, person)
                    done.fulfill()
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }

    
    func testCompactJSON() {
        // test reading a store from compact json interchange
        checkJSON(name: "Compact", checkAddressType: false)
    }
    
    func testNormalizedJSON() {
        // test reading a store from normalized (more verbose) json interchange
        checkJSON(name: "Normalized", checkAddressType: true)
    }
    
 
    func testInterchange() {
        // test encoding into a dictionary in interchange format
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            let names = Set<String>(["Person 1", "Person 2"])
            datastore.get(entitiesOfType: .person, where: "name", contains: names) { (people) in
                let person = people[0]
                datastore.add(properties: [person: self.exampleProperties(owner: people[1], in: datastore)]) { () in
                    datastore.encodeInterchange() { interchange in
                        self.checkInterchangeDictionary(interchange, names: names)
                        
                        done.fulfill()
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }
    
    func testInterchangeJSON() {
        // test encoding into json in interchange format
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            let names = Set<String>(["Person 1", "Person 2"])
            datastore.get(entitiesOfType: .person, where: "name", contains: names) { (people) in
                let person = people[0]
                datastore.add(properties: [person: self.exampleProperties(owner: people[1], in: datastore)]) { () in
                    datastore.encodeJSON() { json in
                        // convert it back from json to a dictionary
                        let interchange = (try! JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: [])) as! [String:Any]
                        self.checkInterchangeDictionary(interchange, names: names)
                        done.fulfill()
                    }
                }
            }
        }
        wait(for: [done], timeout: 1.0)
    }
    
    func testChangeName() {
        // test changing a property of an existing entity
        let created = expectation(description: "loaded")
        loadAndCheck { datastore in
            datastore.get(entityOfType: .person, where: "name", equals: "Person 1") { person in
                guard let person = person else {
                    XCTFail("missing person")
                    created.fulfill()
                    return
                }
                
                var properties = PropertyDictionary()
                properties["name"] = "New Name"
                datastore.add(properties: [person : properties]) {
                    XCTAssertEqual(person.object.string(withKey: .name), "New Name")
                    created.fulfill()
                }
            }
        }
        wait(for: [created], timeout: 1.0)
    }
    
    func testGetPropertyReturnsNewest() {
        // test changing a property and making sure the newest value is returned
        let done = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            datastore.get(entitiesOfType: .test, where: "name", contains: ["test"]) { (entities) in
                XCTAssertEqual(entities.count, 1)
                let entity = entities[0]
                datastore.add(properties: [entity: PropertyDictionary(["thing": "foo"])]) { () in
                    datastore.add(properties: [entity: PropertyDictionary(["thing": "bar"])]) { () in
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
        // test deleting a property
        let done = expectation(description: "done")
        loadJSON(name: "Deletion", expectation: done) { store in
            store.get(entitiesOfType: .test, where: "name", contains: ["Test1"]) { (entities) in
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
