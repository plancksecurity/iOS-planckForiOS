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
        XCTAssertEqual(Constant.htmlFixedFontSize.fixedFontSizeReplaced(),
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
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1 {margin: 0.0px 0.0px 0.0px 0.0px; font: normal '.SF UI Text'; color: #000000}
p.p2 {margin: 0.0px 0.0px 0.0px 0.0px; min-height: 14.0px}
span.s1 {font-family: '.SFUIText'; font-weight: normal; font-style: normal; font-size: 16.0px}
span.s1 {font-family: '.SFUIText'; font-weight: normal; font-style: normal; font-size: 16.0pt}
span.s2 {font-family: 'Helvetica'; font-weight: normal; font-style: normal; font-size: 14.0px}
span.s2 {font-family: 'Helvetica'; font-weight: normal; font-style: normal; font-size: 14.0pt}
</style>
</head>
<body>
<p class="p1"><span class="s1">Jdjdjd</span></p>
<p class="p2"><span class="s2"></span><br></p>
<p class="p1"><span class="s1">Jdjdjd</span></p>
</body>
</html>
"""

        static let htmlExpected = """
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1 {margin: 0.0px 0.0px 0.0px 0.0px; font: normal '.SF UI Text'; color: #000000}
p.p2 {margin: 0.0px 0.0px 0.0px 0.0px; min-height: 14.0px}
span.s1 {font-family: '.SFUIText'; font-weight: normal; font-style: normal; font-size: normal}
span.s1 {font-family: '.SFUIText'; font-weight: normal; font-style: normal; font-size: normal}
span.s2 {font-family: 'Helvetica'; font-weight: normal; font-style: normal; font-size: smaller}
span.s2 {font-family: 'Helvetica'; font-weight: normal; font-style: normal; font-size: smaller}
</style>
</head>
<body>
<p class="p1"><span class="s1">Jdjdjd</span></p>
<p class="p2"><span class="s2"></span><br></p>
<p class="p1"><span class="s1">Jdjdjd</span></p>
</body>
</html>
"""
    }
}

