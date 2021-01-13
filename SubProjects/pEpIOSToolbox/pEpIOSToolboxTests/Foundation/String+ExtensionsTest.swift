//
//  StringTest.swift
//  pEpIOSToolboxTests
//
//  Created by Xavier Algarra on 12/08/2019.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import XCTest

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
        let backspace = "\u{8}"
        XCTAssertFalse(numericString.isBackspace)
        XCTAssertFalse(alphabetString.isBackspace)
        XCTAssertFalse(otherCharacterString.isBackspace)
        XCTAssertTrue(backspace.isBackspace)
    }

    // MARK: - alphaNumericOnly

    func testAlphaNumericOnly_numeric() {
        XCTAssertEqual(numericString.alphaNumericOnly(), numericString)
    }

    func testAlphaNumericOnly_notAlphanumeric() {
        XCTAssertNotEqual(otherCharacterString.alphaNumericOnly(), otherCharacterString)
    }

    func testAlphaNumericOnly_notDigitsStript() {
        let testee = "1234567890 1 !!!\"§$%&/()=?\nabcdefghijklmnopqrstuvwxyz"
        let expected = "12345678901abcdefghijklmnopqrstuvwxyz"
        XCTAssertEqual(testee.alphaNumericOnly(), expected)
    }

    // MARK: - everythingStrippedThatIsNotInCharset

    func testeverythingStrippedThatIsNotInCharset() {
        let testee = "1234567890 1 !!!\"§$%&/()=?\nabcdefghijklmnopqrstuvwxyz"
        let expected = "12345678901"
        let charset = CharacterSet.decimalDigits
        XCTAssertEqual(testee.string(everythingStrippedThatIsNotInCharset: charset),
                          expected)
    }

    // MARK: - String.splitFileExtension

    func testSplitFileExtension() {
        func checkSplitFileExtension(filename: String, name: String, fileExtension: String?) {
            let (resName, resExt) = filename.splitFileExtension()
            XCTAssertEqual(resName, name)
            XCTAssertEqual(resExt, fileExtension)
        }

        checkSplitFileExtension(filename: "blah.asc", name: "blah", fileExtension: "asc")
        checkSplitFileExtension(filename: "blah.txt.asc", name: "blah.txt", fileExtension: "asc")
        checkSplitFileExtension(filename: "blah.txt.gpg.asc",
                                name: "blah.txt.gpg",
                                fileExtension: "asc")
        checkSplitFileExtension(filename: ".asc", name: ".asc", fileExtension: nil)
        checkSplitFileExtension(filename: "noneasc", name: "noneasc", fileExtension: nil)
        checkSplitFileExtension(filename: "emptyext.", name: "emptyext.", fileExtension: nil)
        checkSplitFileExtension(filename: "doubledot..", name: "doubledot..", fileExtension: nil)
        checkSplitFileExtension(filename: ".......", name: ".......", fileExtension: nil)
        checkSplitFileExtension(filename: "single.m", name: "single", fileExtension: "m")
    }
}