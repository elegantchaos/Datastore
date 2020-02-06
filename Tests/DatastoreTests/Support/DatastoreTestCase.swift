// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/11/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import XCTestExtensions

@testable import Datastore

// MARK: - Test Support

class DatastoreTestCase: XCTestCase {
    var container: ContainerWithStore? = nil
    
    func loadAndCheck(url: URL? = nil, completion: @escaping (Datastore) -> Void) {
        DatastoreContainer.load(name: "Test", url: url) { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
                
            case .success(let container):
                self.container = container
                completion(container.store)
            }
        }
    }
    
    func loadJSON(name: String, expectation: XCTestExpectation, completion: @escaping (Datastore) -> Void) {
        let json = testString(named: name, withExtension: "json")
        DatastoreContainer.load(name: name, json: json) { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
                expectation.fulfill()
                
            case .success(let container):
                self.container = container
                completion(container.store)
            }
        }
    }
    
    func createTestFile() {
        let created = expectation(description: "created")
        let container = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Resources")
        let url = container.appendingPathComponent("Test.sqlite")
        try? FileManager.default.removeItem(at: url)
        let json = testString(named: "Test", withExtension: "json")
        loadAndCheck(url: url) { store in
            store.decode(json: json) { decodeResult in
                XCTAssertSuccess(decodeResult, expectation: created) { _ in
                    store.save() { saveResult in
                        XCTAssertSuccess(saveResult, expectation: created)
                    }
                }
            }
        }
        wait(for: [created], timeout: 1.0)
    }

    func exampleProperties(date: Date = Date(), owner: EntityReference, in store: Datastore) -> PropertyDictionary {
        var properties = PropertyDictionary()
        properties["address"] = PropertyValue("123 New St", type: "address")
        properties["date"] = date
        properties["integer"] = 123
        properties["double"] = 456.789
        properties["boolean"] = true
        properties["owner"] = (owner, "owner")
        properties["data"] = "encoded string".data(using: .utf8)
        return properties
    }

}
