//
//  Array+SortingAndSearchingTest.swift
//  pEpIOSToolboxTests
//
//  Created by Dirk Zimmermann on 21.11.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import XCTest

class ArraySortingAndSearchingTest: XCTestCase {
    func testUnique001() {
        XCTAssertEqual([1,2,2,3,3,4,4,5,5].uniques(), [1,2,3,4,5])
    }
}
