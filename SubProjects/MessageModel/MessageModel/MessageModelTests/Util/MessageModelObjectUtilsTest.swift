//
//  MessageModelObjectUtilsTest.swift
//  MessageModelTests
//
//  Created by Alejandro Gelos on 04/03/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData
@testable import MessageModel

class MessageModelObjectUtilsTest: PersistentStoreDrivenTestBase {
    var sampleCdMessage: CdMessage?

    override func setUp() {
        super.setUp()
        sampleCdMessage = TestUtil.createMessage(moc: moc)
        try? moc.save()
    }

    override func tearDown() {
        sampleCdMessage = nil
        super.tearDown()
    }

    func testGetMessageFromCdMessage() {
        // Given
        guard let cdMessage = sampleCdMessage else {
            XCTFail()
            return
        }
        // When
        let message = MessageModelObjectUtils.getMessage(fromCdMessage: cdMessage,
                                                         context: moc)
        // Then
        XCTAssertNotNil(message)
        XCTAssertNotNil(message.uuid)
        XCTAssertEqual(message.uuid, cdMessage.uuid)
        XCTAssertEqual(message.cdObject, cdMessage)
        XCTAssertEqual(message.moc, moc)
    }
}
