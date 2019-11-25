// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/11/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import XCTestExtensions

@testable import Datastore

// MARK: - Test Support

class DatastoreTestCase: XCTestCase {
    func loadAndCheck(url: URL? = nil, completion: @escaping (Datastore) -> Void) {
        Datastore.load(name: "Test", url: url) { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
                
            case .success(let store):
                completion(store)
            }
        }
    }
    
    func loadJSON(name: String, expectation: XCTestExpectation, completion: @escaping (Datastore) -> Void) {
        let json = testString(named: name, withExtension: "json")
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
    
}
