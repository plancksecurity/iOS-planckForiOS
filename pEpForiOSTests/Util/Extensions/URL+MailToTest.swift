//
//  URL+MailToTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 03.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class URL_MailToTest: XCTestCase {

    func testFirstRecipientAddress_onlyOne() {
        let url = URL(string: "mailto:someone@example.com")
        let expected = "someone@example.com"
        assertFirstRecipientAddress(url: url, expecteation: expected)
    }

    func testFirstRecipientAddress_complex_percentageEscaped() {
        let url = URL(string: "mailto:someone@example.com" +
            "?cc=elseone@example.com&subject=This%20is%20the%20subject&body=This%20is%20the%20body")
        let expected = "someone@example.com"
        assertFirstRecipientAddress(url: url, expecteation: expected)
    }
}

// MARK: - HELPER

private func assertFirstRecipientAddress(url: URL?, expecteation: String) {
    guard let url = url else {
        XCTFail("Nothing to test")
        return
    }
    let testee = url.firstRecipientAddress()
    XCTAssertEqual(testee, expecteation)
}
