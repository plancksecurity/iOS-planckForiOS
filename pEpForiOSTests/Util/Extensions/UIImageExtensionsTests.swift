//
//  UIImageExtensionsTests.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 15.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpIOSToolbox
@testable import pEpForiOS

class UIImageExtensionsTests: XCTestCase {
    private struct Constant {
        // "small-animated-gif.gif" file has 44 frames
        static let expectedNumbersOfFrames = 44
    }
    func testZeroFrame() {
        let gifEmptyData = Data()
        let gifImg = UIImage.image(gifData: gifEmptyData)
        XCTAssertNil(gifImg)
    }

    func testSingleFrame() {
        let gifImg = UIImage.image(gifData: getStandardGifData())
        XCTAssertNotNil(gifImg)
    }

    // Related to bug IOS-1696 (large) animated gif causes iOS app to crash
    func testLargeGif() {
        let image = UIImage.image(gifData: getAnimatedLargeGifData())
        XCTAssertNotNil(image)
        XCTAssertNil(image?.images)
    }

    func testSmallGif() {
        let image = UIImage.image(gifData: getAnimatedSmallGifData())
        XCTAssertNotNil(image)
        XCTAssertNotNil(image?.images)
        XCTAssertEqual(Constant.expectedNumbersOfFrames, image?.images?.count)
    }
}

// MARK: - Mock Data

extension UIImageExtensionsTests {
    private func getAnimatedLargeGifData() -> Data {
        let imageFileName = "large-animated-gif.gif"
        guard let imageData = MiscUtil.loadData(bundleClass: UIImageExtensionsTests.self,
                                                fileName: imageFileName) else {
            XCTFail("imageData is nil!")
            return Data()
        }
        return imageData
    }
    private func getAnimatedSmallGifData() -> Data {
        let imageFileName = "small-animated-gif.gif"
        guard let imageData = MiscUtil.loadData(bundleClass: UIImageExtensionsTests.self,
                                                fileName: imageFileName) else {
            XCTFail("imageData is nil!")
            return Data()
        }
        return imageData
    }
    private func getStandardGifData() -> Data {
        let imageFileName = "icon_001.gif"
        guard let imageData = MiscUtil.loadData(bundleClass: UIImageExtensionsTests.self,
                                                fileName: imageFileName) else {
            XCTFail("imageData is nil!")
            return Data()
        }
        return imageData
    }
}

