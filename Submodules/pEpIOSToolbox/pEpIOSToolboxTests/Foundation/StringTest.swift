//
//  StringTest.swift
//  pEpIOSToolboxTests
//
//  Created by Xavier Algarra on 12/08/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import XCTest
import pEpIOSToolbox

class StringTest: XCTestCase {

    func testIsDigits() {
        let string1 = "0123456789"
        let string2 = "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let string3 = #"ª!"·$%&/()=?¿^*¨_:;,.-´`+¡'"#
        XCTAssertTrue(string1.isDigits)
        XCTAssertFalse(string2.isDigits)
        XCTAssertFalse(string3.isDigits)
        var mixedString = string1 + string2 + string3
        mixedString = String(mixedString.shuffled())
        XCTAssertFalse(mixedString.isDigits)
    }

    func testIsBackspace() {
        let string1 = "0123456789"
        let string2 = "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let string3 = #"ª!"·$%&/()=?¿^*¨_:;,.-´`+¡'"#
        //this is backspace in swift
        let string4 = "\u{8}"
        XCTAssertFalse(string1.isBackspace)
        XCTAssertFalse(string2.isBackspace)
        XCTAssertFalse(string3.isBackspace)
        XCTAssertTrue(string4.isBackspace)
    }
}
