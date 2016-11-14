//
//  ObservableModelTest.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 11/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import MessageModel

class ObservableModelTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let _ = PersistentSetup()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testModelObserver() {

        class MockModel:ModelSaveProtocol {
            var dirty: Bool = false
            var saveIsCalled: XCTestExpectation?
            var mockProperty = "" {
                didSet{
                    notifyObserver()
                    dirty = true;
                }
            }
            func save() {
                dirty = false
                self.saveIsCalled?.fulfill()

            }

        }

        let mm = MockModel();
        mm.saveIsCalled = expectation(description: "mm_dirty")
        XCTAssertFalse(mm.dirty)
        mm.mockProperty = "new string"
        XCTAssertTrue(mm.dirty)
        

        waitForExpectations(timeout: TestUtil.waitTime, handler: { (error) in
            XCTAssertNil(error)
            XCTAssertFalse(mm.dirty)
        })



    }

    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
