//
//  MiscTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest
@testable import pEpIOSToolbox
import MessageModel

/**
 Tests for things not covered elsewhere.
 */
class MiscTests: XCTestCase {
    /**
     Tests the interaction between certain IMAP values like UID,
     that are supposed to be 32-bit values, and represented in the DB as Int32,
     and their counterpart in the UI, which often uses UInt.
     */
    func testUInt32ToUInt() {
        let i32 = UInt32.max
        let u = UInt(i32)
        let i1 = Int64(i32)
        let i2 = Int64(u)
        XCTAssertEqual(i1, i2)
        let i32Next = UInt32(u)
        let i3 = Int64(i32Next)
        XCTAssertEqual(i1, i3)
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
