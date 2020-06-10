//
//  AttributedString+HTML.swift
//  pEpForiOSTests
//
//  Created by Adam Kowalski on 10/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class AttributedString_HTML: XCTestCase {

    var expectedFontSize: String {
        get {
            if #available(iOS 13, *) {
                return "-2" // BTW: very interesting...
            } else {
                return "12.00pt"
            }
        }
    }

    // IOS-2256
    func testAttributedStringWithoutSpecifiedFontsToHtmlString() {
        let attributedString = NSAttributedString(string: "This is an example test")

        let html = attributedString.toHtml(inlinedAttachments: [])

        XCTAssertEqual(html.html, "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n<meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n<title></title>\n<meta name=\"Generator\" content=\"Cocoa HTML Writer\">\n<style type=\"text/css\">\np.p1 {margin: 0.0px 0.0px 0.0px 0.0px}\nspan.s1 {font-family: \'Helvetica\'; font-weight: normal; font-style: normal; font-size: \(expectedFontSize)}\n</style>\n</head>\n<body>\n<p class=\"p1\"><span class=\"s1\">This is an example test</span></p>\n</body>\n</html>\n")
    }
}
