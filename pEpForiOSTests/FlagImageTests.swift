//
//  FlagImageTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 02/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import UIKit

@testable import pEpForiOS
import MessageModel

class FlagImageTests: XCTestCase {
    func testSimple() {
        let fi = FlagImages.create(imageSize: CGSize(width: 16, height: 16))

        XCTAssertNotNil(fi.notSeenImage)
        XCTAssertNotNil(fi.flaggedImage)
        XCTAssertNotNil(fi.flaggedAndNotSeenImage)

        let msg = Message.fakeMessage(uuid: MessageID.generate())

        msg.imapFlags.seen = true
        XCTAssertNil(fi.flagsImage(message: msg))

        msg.imapFlags.flagged = true
        XCTAssertEqual(fi.flagsImage(message: msg), fi.flaggedImage)

        msg.imapFlags.seen = false
        XCTAssertEqual(fi.flagsImage(message: msg), fi.flaggedImage)

        msg.imapFlags.flagged = false
        XCTAssertNil(fi.flagsImage(message: msg))
    }
}
