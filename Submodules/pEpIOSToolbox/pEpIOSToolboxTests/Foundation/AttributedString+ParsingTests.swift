//
//  AttributedString+ParsingTests.swift
//  pEpIOSToolboxTests
//
//  Created by Adam Kowalski on 17/03/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import XCTest

class AttributedString_ParsingTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testToCitation() {
//        let attribString = NSAttributedString(string: "First line\nSecond line\nThird line")
        let src = """
        <div>
          <p>Taken from wikpedia</p>
          <img src="data:image/png;charset=utf-8;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
            AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
                9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" />
        </div>
        """

        let htmlData = src.data(using: .utf16,
                                 allowLossyConversion: true)
        let options: [NSAttributedString.DocumentReadingOptionKey : Any] =
            [.documentType : NSAttributedString.DocumentType.html]
        let attribString = try! NSAttributedString(data: htmlData ?? Data(),
                                                   options: options,
                                                   documentAttributes: nil)

        let sth = attribString.toCitation()
        // WIP: 

    }

    func testCitationVerticalLineToBlockquote() {
        let input = NSAttributedString(string: "     ")
        let sth = input.citationVerticalLineToBlockquote()
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
