//
//  URL+ExtensionsTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 24.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class URL_ExtensionsTest: XCTestCase {
    let pathBuilder = "file://ma/path/to/"
    let jpgExt = "jpg"
    let fileName = "nice_pic"
    var url: URL?

    override func setUp() {
        url = completeUrl()
    }

    func testFileName() {
        let testee = url?.fileName()
        XCTAssertEqual(testee, fileName)
    }

    func testFileName_explicit() {
        let testee = url?.fileName(includingExtension: false)
        XCTAssertEqual(testee, fileName)
    }

    func testFileName_inclExtension() {
        let testee = url?.fileName(includingExtension: true)
        let expected = fileName + "." + jpgExt
        XCTAssertEqual(testee, expected)
    }

    // MARK: - HELPER

    private func completeUrl() -> URL? {
        return url(forFileNamed: fileName)
    }

    private func url(forFileNamed name: String) -> URL? {
        let pathString = path(forFileNamed: name)
        return URL(string: pathString)
    }

    private func path(forFileNamed name: String) -> String {
        return pathBuilder + name + "." + jpgExt
    }
}
