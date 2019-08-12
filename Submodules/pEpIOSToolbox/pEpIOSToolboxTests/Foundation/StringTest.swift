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
    let numericString = "0123456789"
    let alphabetString = "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    let otherCharacterString = #"ª!"·$%&/()=?¿^*¨_:;,.-´`+¡'"#

    func testIsDigits() {
        XCTAssertTrue(numericString.isDigits)
        XCTAssertFalse(alphabetString.isDigits)
        XCTAssertFalse(otherCharacterString.isDigits)
        var mixedString = numericString + alphabetString + otherCharacterString
        mixedString = String(mixedString.shuffled())
        XCTAssertFalse(mixedString.isDigits)
    }
    func testIsBackspace() {

        //this is backspace in swift
        let string4 = "\u{8}"
        XCTAssertFalse(numericString.isBackspace)
        XCTAssertFalse(alphabetString.isBackspace)
        XCTAssertFalse(otherCharacterString.isBackspace)
        XCTAssertTrue(string4.isBackspace)
    }
}
