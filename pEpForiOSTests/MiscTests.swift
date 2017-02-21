//
//  MiscTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest

import pEpForiOS
import MessageModel

/**
 Tests for things not covered elsewhere.
 */
class MiscTests: XCTestCase {
    func testSignedNumbers32() {
        let u: UInt32 = UInt32.max
        let s: Int32 = Int32(bitPattern: u)
        let u1: UInt32 = UInt32(bitPattern: s)
        XCTAssertEqual(u1, UInt32.max)

        let n = NSNumber.init(value: s as Int32)
        let u2: UInt32 = UInt32(bitPattern: n.int32Value)
        XCTAssertEqual(u2, UInt32.max)
    }

    func testMimeTypeJson() {
        let mimeTypeController = MimeTypeUtil()
        let s = mimeTypeController?.getMimeType(fileExtension: "pdf")
        XCTAssertEqual(s, "application/pdf")
    }

    func testBinaryIndex() {
        func shouldInsert(e1: Int, e2: Int) -> Bool {
            if e1 < e2 || e1 == e2 {
                return true
            }
            return false
        }

        let ar = [1, 3, 4, 5, 7, 8, 9]

        for e in 1...10 {
            let i1 = ar.insertIndexByTraversing(element: e, shouldInsert: shouldInsert)
            let i2 = ar.insertIndex(element: e, shouldInsert: shouldInsert)
            XCTAssertEqual(i1, i2)
        }

        XCTAssertEqual(ar.insertIndexByTraversing(element: 6, shouldInsert: shouldInsert), 4)
        XCTAssertEqual(ar.insertIndexByTraversing(element: 2, shouldInsert: shouldInsert), 1)
        XCTAssertEqual(ar.insertIndexByTraversing(element: 9, shouldInsert: shouldInsert), 6)
        XCTAssertEqual(ar.insertIndexByTraversing(element: 10, shouldInsert: shouldInsert), 7)
    }
}
