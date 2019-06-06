//
//  URL+MIME.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 24.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import pEpIOSToolbox
import MessageModel

class URL_MimeTest: XCTestCase {
    let pathBuilder = "file://ma/path/to/nice_pic"
    let mimeUtils = MimeTypeUtils()

    func testJpg() {
        let jpgExt = "jpg"
        let url = urlWithExtension(ext: jpgExt)
        let testee = mimeUtils?.mimeType(fromURL: url)
        let expected = mimeUtils?.mimeType(fromFileExtension: jpgExt)
        XCTAssertEqual(testee, expected)
    }

    // MARK: - HELPER

    private func urlWithExtension(ext: String) -> URL {
        guard let url = URL(string: pathBuilder) else {
            XCTFail("Ui!")
            return URL(fileURLWithPath: "Ui again")
        }
        return url.appendingPathExtension(ext)
    }
}
