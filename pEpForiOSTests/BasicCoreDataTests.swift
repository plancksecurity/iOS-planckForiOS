//
//  BasicCoreDataTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 25/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

import CoreData

class BasicCoreDataTests: XCTestCase {
    var coreDataUtil: CoreDataUtil!
    
    override func setUp() {
        super.setUp()
        coreDataUtil = CoreDataUtil()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    /**
     Proof of concept for using managed object context in unit tests.
     */
    func testNewMessage() {
        let message = NSEntityDescription.insertNewObjectForEntityForName(
            Message.entityName(),
            inManagedObjectContext: coreDataUtil.testManagedObjectContext) as? Message
        XCTAssertNotNil(message)
        message!.subject = "Subject"
        XCTAssertNotNil(message?.subject)
    }
}
