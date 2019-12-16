// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/12/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import XCTest
import XCTestExtensions

@testable import Datastore

class PropertyKeyTests: DatastoreTestCase {
    func testNamed() {
        let key = PropertyKey("test")
        XCTAssertEqual(key.value, "test")
    }
    
    func testStringLiteral() {
        let key: PropertyKey = "test"
        XCTAssertEqual(key.value, "test")
    }
    
    func testArray() {
        let key = PropertyKey(array: "test")
        XCTAssertTrue(key.value.starts(with: "test-"))
    }
    
    func testNamedResolution() {
        let key = PropertyKey("test")
        let loaded = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            let resolved = key.resolve(in: datastore)
            XCTAssertEqual(resolved.value, "test")
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 1.0)
    }

    func testReferenceResolution() {
        let person = Entity.identifiedBy("some-id", createAs: .person)
        let key = PropertyKey(reference: person, name: "test")
        let loaded = expectation(description: "loaded")
        loadAndCheck { (datastore) in
            let resolved = key.resolve(in: datastore)
            XCTAssertEqual(resolved.value, "test-some-id")
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 1.0)
    }

}

