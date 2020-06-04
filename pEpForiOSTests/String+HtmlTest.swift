//
//  String+HtmlTest.swift
//  pEpIOSToolboxTests
//
//  Created by Adam Kowalski on 04/06/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import XCTest

class String_HtmlTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
//        let styleOpenTagIndex = Constant.htmlFixedFontSize.find
//        let styleCloseTagIndex = Constant.htmlFixedFontSize.firstIndex(of: "</style>")

    }

    func testHtmlFixedFontSizeResolver() throws {
        XCTAssertEqual(Constant.htmlFixedFontSize.fixedFontSizeReplacer(), Constant.htmlExpected)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
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
p.p1 {margin: 0.0px 0.0px 0.0px 0.0px; font: 19.0px '.AppleSystemUIFont'; color: #000000}
span.s1 {font-family: 'UICTFontTextStyleBody'; font-weight: normal; font-style: normal; font-size: 17.00px}
</style>
</head>
<body>
<p class="p1"><span class="s1">Test10</span></p>
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
p.p1 {margin: 0.0px 0.0px 0.0px 0.0px; font: +1 '.AppleSystemUIFont'; color: #000000}
span.s1 {font-family: 'UICTFontTextStyleBody'; font-weight: normal; font-style: normal; }
</style>
</head>
<body>
<p class="p1"><span class="s1">Test10</span></p>
</body>
</html>
"""

        static let htmlExpected2 = """
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<title></title>
<meta name="Generator" content="Cocoa HTML Writer">
<style type="text/css">
p.p1 {margin: 0.0px 0.0px 0.0px 0.0px; font: +1 '.AppleSystemUIFont'; color: #000000}
span.s1 {font-family: 'UICTFontTextStyleBody'; font-weight: normal; font-style: normal; font-size: +1}
</style>
</head>
<body>
<p class="p1"><span class="s1">Test10</span></p>
</body>
</html>
"""
    }

}
