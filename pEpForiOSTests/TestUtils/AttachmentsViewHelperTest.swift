//
//  AttachmentsViewHelperTest.swift
//  pEpForiOSTests
//
//  Created by Adam Kowalski on 25/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

final class AttachmentsViewHelperTest: CoreDataDrivenTestBase {

    // Related to bug IOS-1696 (large) animated gif causes iOS app to crash
    func testLargeGif() {
        let image = UIImage.image(gifData: getAnimatedLargeGifData())
        XCTAssertNotNil(image)
        XCTAssertNil(image?.images)
    }

    func testSmallGif() {
        let image = UIImage.image(gifData: getAnimatedSmallGifData())
        let expectedNumbersOfFrames = 44
        XCTAssertNotNil(image)
        XCTAssertNotNil(image?.images)
        XCTAssertEqual(expectedNumbersOfFrames, image?.images?.count)
    }

    func testNoGif() {
        let image = UIImage.image(gifData: getStandardGifData())
        XCTAssertNotNil(image)
        XCTAssertNil(image?.images)
    }

    func testEmptyGif() {
        let image = UIImage.image(gifData: Data())
        XCTAssertNil(image)
    }
}

// MARK: - Mock Data

extension AttachmentsViewHelperTest {
    private func getAnimatedLargeGifData() -> Data {
        let imageFileName = "large-animated-gif.gif"
        guard let imageData = TestUtil.loadData(fileName: imageFileName) else {
            XCTFail("imageData is nil!")
            return Data()
        }
        return imageData
    }
    private func getAnimatedSmallGifData() -> Data {
        let imageFileName = "small-animated-gif.gif"
        guard let imageData = TestUtil.loadData(fileName: imageFileName) else {
            XCTFail("imageData is nil!")
            return Data()
        }
        return imageData
    }
    private func getStandardGifData() -> Data {
        let imageFileName = "icon_001.gif"
        guard let imageData = TestUtil.loadData(fileName: imageFileName) else {
            XCTFail("imageData is nil!")
            return Data()
        }
        return imageData
    }
}
