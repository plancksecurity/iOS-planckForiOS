//
//  PEPUtilTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 21.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class PEPUtilTest: XCTestCase {

    let plainSignature = String.pepSignature
    let htmlSignature = String.pEpSignatureHtml

    func testSignatures() {
        XCTAssertNotNil(plainSignature)
        XCTAssertNotNil(htmlSignature)
        XCTAssertNotEqual(plainSignature, htmlSignature)
    }

    func testSignature_middle() {
        let testee = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata \(plainSignature) sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
        assertReplaceWithHref(testee)
    }

    func testSignature_start() {
        let testee = "\(plainSignature) Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
        assertReplaceWithHref(testee)
    }

    func testSignature_end() {
        let testee = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. \(plainSignature) "
        assertReplaceWithHref(testee)
    }

    func testSignature_none() {
        let testee = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
        assertReplaceWithHref(testee, isIncluded: false)
    }

    func testSignature_only() {
        let testee = plainSignature
        assertReplaceWithHref(testee)
    }

    // MARK: - Helper

    private func assertReplaceWithHref(_ testee: String, isIncluded: Bool = true) {
        if isIncluded {
        XCTAssertTrue(testee.contains(find: String.pepSignature))
        } else {
            XCTAssertFalse(testee.contains(find: String.pepSignature))
        }
        XCTAssertFalse(testee.contains(find: String.pEpSignatureHtml))

        let href = testee.replacingOccurrencesOfPepSignatureWithHtmlVersion()
        if isIncluded {
            XCTAssertTrue(href.contains(find: String.pEpSignatureHtml))
        } else {
            XCTAssertFalse(href.contains(find: String.pepSignature))
            XCTAssertFalse(href.contains(find: String.pEpSignatureHtml))
        }
    }
}
