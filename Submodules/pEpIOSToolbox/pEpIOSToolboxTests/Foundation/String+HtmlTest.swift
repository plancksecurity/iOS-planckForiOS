//
//  String+HtmlTest.swift
//  pEpIOSToolboxTests
//
//  Created by Adam Kowalski on 04/06/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import XCTest
@testable import pEpIOSToolbox

class String_HtmlTest: XCTestCase {
    func testHtmlFixedFontSizeResolver() {
        XCTAssertEqual(Constant.htmlFixedFontSize.fixedFontSizeRemoved(),
                       Constant.htmlExpected)
    }
}

// MARK: - MOCK DATA

extension String_HtmlTest {

    struct Constant {
        static let htmlFixedFontSize = """
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1 {margin: 0.0px 0.0px 0.0px 0.0px; font: 6.0px '.AppleSystemUIFont'; color: #000000}
p.p2 {margin: 0.0px 0.0px 0.0px 0.0px; font: 11.0px '.AppleSystemUIFont'; color: #000000}
p.p3 {margin: 0.0px 0.0px 0.0px 0.0px; font: 12.0px '.AppleSystemUIFont'; color: #000000}
p.p4 {margin: 0.0px 0.0px 0.0px 0.0px; font: 13.0px '.AppleSystemUIFont'; color: #000000}
p.p5 {margin: 0.0px 0.0px 0.0px 0.0px; font: 14.0px '.AppleSystemUIFont'; color: #000000}
p.p6 {margin: 0.0px 0.0px 0.0px 0.0px; font: 15.0px '.AppleSystemUIFont'; color: #000000}
p.p7 {margin: 0.0px 0.0px 0.0px 0.0px; font: 16.0px '.AppleSystemUIFont'; color: #000000}
p.p8 {margin: 0.0px 0.0px 0.0px 0.0px; font: 17.0px '.AppleSystemUIFont'; color: #000000}
p.p9 {margin: 0.0px 0.0px 0.0px 0.0px; font: 18.0px '.AppleSystemUIFont'; color: #000000}
p.p10 {margin: 0.0px 0.0px 0.0px 0.0px; font: 19.0px '.AppleSystemUIFont'; color: #000000}
p.p11 {margin: 0.0px 0.0px 0.0px 0.0px; font: 20.0px '.AppleSystemUIFont'; color: #000000}
p.p12 {margin: 0.0px 0.0px 0.0px 0.0px; font: 21.0px '.AppleSystemUIFont'; color: #000000}
p.p13 {margin: 0.0px 0.0px 0.0px 0.0px; font: 22.0px '.AppleSystemUIFont'; color: #000000}
p.p14 {margin: 0.0px 0.0px 0.0px 0.0px; font: 23.0px '.AppleSystemUIFont'; color: #000000}
p.p15 {margin: 0.0px 0.0px 0.0px 0.0px; font: 24.0px '.AppleSystemUIFont'; color: #000000}
p.p16 {margin: 0.0px 0.0px 0.0px 0.0px; font: 25.0px '.AppleSystemUIFont'; color: #000000}
p.p17 {margin: 0.0px 0.0px 0.0px 0.0px; font: 26.0px '.AppleSystemUIFont'; color: #000000}
p.p18 {margin: 0.0px 0.0px 0.0px 0.0px; font: 36.0px '.AppleSystemUIFont'; color: #000000}
p.p19 {margin: 0.0px 0.0px 0.0px 0.0px; font: 38.0px '.AppleSystemUIFont'; color: #000000}
p.p20 {margin: 0.0px 0.0px 0.0px 0.0px; font: 41.0px '.AppleSystemUIFont'; color: #000000}
p.p21 {margin: 0.0px 0.0px 0.0px 0.0px; font: 72.0px '.AppleSystemUIFont'; color: #000000}
span.s1 {font-family: 'UICTFontTextStyleBody'; font-weight: normal; font-style: normal; font-size: 17.00px}
</style>
</head>
<body>
</body>
</html>
"""

        static let htmlExpected = """
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1 {margin: 0.0px 0.0px 0.0px 0.0px; font: x-small '.AppleSystemUIFont'; color: #000000}
p.p2 {margin: 0.0px 0.0px 0.0px 0.0px; font: x-small '.AppleSystemUIFont'; color: #000000}
p.p3 {margin: 0.0px 0.0px 0.0px 0.0px; font: small '.AppleSystemUIFont'; color: #000000}
p.p4 {margin: 0.0px 0.0px 0.0px 0.0px; font: small '.AppleSystemUIFont'; color: #000000}
p.p5 {margin: 0.0px 0.0px 0.0px 0.0px; font: smaller '.AppleSystemUIFont'; color: #000000}
p.p6 {margin: 0.0px 0.0px 0.0px 0.0px; font: smaller '.AppleSystemUIFont'; color: #000000}
p.p7 {margin: 0.0px 0.0px 0.0px 0.0px;  '.AppleSystemUIFont'; color: #000000}
p.p8 {margin: 0.0px 0.0px 0.0px 0.0px;  '.AppleSystemUIFont'; color: #000000}
p.p9 {margin: 0.0px 0.0px 0.0px 0.0px; font: larger '.AppleSystemUIFont'; color: #000000}
p.p10 {margin: 0.0px 0.0px 0.0px 0.0px; font: larger '.AppleSystemUIFont'; color: #000000}
p.p11 {margin: 0.0px 0.0px 0.0px 0.0px; font: larger '.AppleSystemUIFont'; color: #000000}
p.p12 {margin: 0.0px 0.0px 0.0px 0.0px; font: larger '.AppleSystemUIFont'; color: #000000}
p.p13 {margin: 0.0px 0.0px 0.0px 0.0px; font: large '.AppleSystemUIFont'; color: #000000}
p.p14 {margin: 0.0px 0.0px 0.0px 0.0px; font: large '.AppleSystemUIFont'; color: #000000}
p.p15 {margin: 0.0px 0.0px 0.0px 0.0px; font: large '.AppleSystemUIFont'; color: #000000}
p.p16 {margin: 0.0px 0.0px 0.0px 0.0px; font: large '.AppleSystemUIFont'; color: #000000}
p.p17 {margin: 0.0px 0.0px 0.0px 0.0px; font: x-large '.AppleSystemUIFont'; color: #000000}
p.p18 {margin: 0.0px 0.0px 0.0px 0.0px; font: x-large '.AppleSystemUIFont'; color: #000000}
p.p19 {margin: 0.0px 0.0px 0.0px 0.0px; font: x-large '.AppleSystemUIFont'; color: #000000}
p.p20 {margin: 0.0px 0.0px 0.0px 0.0px; font: x-large '.AppleSystemUIFont'; color: #000000}
p.p21 {margin: 0.0px 0.0px 0.0px 0.0px; font: x-large '.AppleSystemUIFont'; color: #000000}
span.s1 {font-family: 'UICTFontTextStyleBody'; font-weight: normal; font-style: normal; }
</style>
</head>
<body>
</body>
</html>
"""
    }
}

