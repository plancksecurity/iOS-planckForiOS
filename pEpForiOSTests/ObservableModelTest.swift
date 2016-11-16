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
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    override func tearDown() {
        persistentSetup = nil
        super.tearDown()
    }

    func testModelObserver() {

        class MockModel:ModelSaveProtocol {
            public struct ImapFlags {
                public var deleted = false
                public var draft = false
                public var flagged = false
                public var recent = false
                public var seen = false
            }

            open var imapFlags: ImapFlags? = ImapFlags() {
                didSet{
                    notifyObserver()
                }
            }
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
        //mm.mockProperty = "new string"
        mm.imapFlags?.draft = true
        XCTAssertTrue(mm.dirty)
        
        waitForExpectations(timeout: TestUtil.waitTime, handler: { (error) in
            XCTAssertNil(error)
            XCTAssertFalse(mm.dirty)
        })
    }
}
