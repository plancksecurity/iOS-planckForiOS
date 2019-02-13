//
//  UIImageExtensionsTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 15.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import Foundation
import pEpIOSToolbox

@testable import pEpForiOS

class UIImageExtensionsTests: XCTestCase {
    func testZeroFrame() {
        let gifData = Data()
        let gifImg = UIImage.image(gifData: gifData)
        XCTAssertNil(gifImg)
    }

    func testSingleFrame() {
        guard let gifData = TestUtil.loadData(fileName: "icon_001.gif") else {
            XCTFail()
            return
        }
        let gifImg = UIImage.image(gifData: gifData)
        XCTAssertNotNil(gifImg)
    }
}
