//
//  DatastoreTests.swift
//  DatastoreTests
//
//  Created by Developer on 16/09/2019.
//  Copyright © 2019 Developer. All rights reserved.
//

import XCTest
@testable import Datastore

class DatastoreTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreation() {
        let loaded = expectation(description: "loaded")
        Datastore.load(name: "Test") { (result) in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
            
            case .success(let store):
                loaded.fulfill()
//                let person = store.getEntity(named: "Test", kind: "Person")
            }
        }

        wait(for: [loaded], timeout: 1.0)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
