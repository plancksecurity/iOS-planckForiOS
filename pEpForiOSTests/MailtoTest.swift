//
//  MailtoTest.swift
//  pEpForiOSTests
//
//  Created by Martin Brude on 07/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class MailtoTest: XCTestCase {

    func testMailtoNil() {
        let urlString = "http://www.google.com"
        if let url = URL(string: urlString) {
            let mailto = Mailto(url: url)
            XCTAssertNil(mailto)
        }
    }

    func testNonMailtoFields() {
        let urlString = "mailto:"

        if let url = URL(string: urlString), let mailto = Mailto(url: url) {
            XCTAssertNil(mailto.tos)
            XCTAssertNil(mailto.ccs)
            XCTAssertNil(mailto.bccs)
            XCTAssertNil(mailto.subject)
            XCTAssertNil(mailto.body)
        } else {
            XCTFail()
        }
    }

    func testMailtoWithAllFields() throws {
        let urlString = "mailto:martin@martin.com,aaa@pepp.com?cc=a@a.com,b@b.com&bcc=c@c.com,d@d.com&subject=subject&body=body%0D%0Aasdas%0D%0A%0D%0Aa"

        if let url = URL(string: urlString), let mailto = Mailto(url: url) {
            guard let tos = mailto.tos else {
                XCTFail("TOs is nil")
                return
            }
            guard let bccs = mailto.bccs else {
                XCTFail("BCCs is nil")
                return
            }
            guard let ccs = mailto.ccs else {
                XCTFail("CCs is nil")
                return
            }
            guard let body = mailto.body else {
                XCTFail("Body is nil")
                return
            }
            guard let subject = mailto.subject else {
                XCTFail("Subject is nil")
                return
            }

            XCTAssertTrue(tos.contains("martin@martin.com"))
            XCTAssertTrue(tos.contains("aaa@pepp.com"))
            XCTAssertTrue(ccs.contains("a@a.com"))
            XCTAssertTrue(ccs.contains("b@b.com"))
            XCTAssertTrue(bccs.contains("c@c.com"))
            XCTAssertTrue(bccs.contains("d@d.com"))
            XCTAssertTrue(body.contains("body\r\nasdas\r\n\r\na"))
            XCTAssertTrue(subject.contains("subject"))
        } else {
            XCTFail("URL or mailto is nil")
        }
    }
}
