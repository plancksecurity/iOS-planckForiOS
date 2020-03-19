//
//  MimeTypeUtilsTest.swift
//  MessageModelTests
//
//  Created by Alejandro Gelos on 08/05/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel

class MimeTypeUtilsTest: XCTestCase {

    func testMimeTypeFromFileExtension() {
        let fileExtension = ["h261",
                             "ps",
                             "aas",
                             "adp",
                             "jpg",
                             "png",
                             "gif",
                             "pdf"]

        let expectedMimeTypes = ["application/octet-stream",
                                 "application/postscript",
                                 "application/octet-stream",
                                 "application/octet-stream",
                                 "image/jpeg",
                                 "image/png",
                                 "image/gif",
                                 "application/pdf"]
        // When
        let mimeTypes = fileExtension.map { MimeTypeUtils.mimeType(fromFileExtension: $0) }

        // Then
        XCTAssertEqual(mimeTypes, expectedMimeTypes)
    }

    func testFileExtensionFromMimeType() {
        // Given
        guard let testee = MimeTypeUtils() else {
            XCTFail()
            return
        }
        let mimeTypes = ["video/h261", "application/vnd.americandynamics.acc",
                         "application/x-ace-compressed", "application/vnd.acucobol",
                         "application/internet-property-stream", "audio/adpcm", "image/jpeg"]

        let expectedFileExtension = ["h261", "acc","ace", "acu", "acx", "adp", "jpg"]
        // When
        let fileExtension = mimeTypes.map { testee.fileExtension(fromMimeType: $0) }

        // Then
        XCTAssertEqual(fileExtension, expectedFileExtension)
    }

    func testMimeTypeFromURL() {
        // Given
        guard let sampleURL = URL(string: "www.google.com/myimg.jpg") else {
                XCTFail()
                return
        }
        let expectedMimeType = "image/jpeg"

        // When
        let mimeType = MimeTypeUtils.mimeType(fromURL: sampleURL)

        // Then
        XCTAssertEqual(mimeType, expectedMimeType)
    }

    func testIsImage_mimeTypeImage() {
        // Given
        let imageMimeTypes = ["image/png", "image/jpeg", "image/gif"]

        // When
        let areImages = imageMimeTypes.map { MimeTypeUtils.isImage(mimeType: $0) }

        // Then
        areImages.forEach { XCTAssertTrue($0) }
    }

    func testIsImage_mimeTypeNoImage() {
        // Given
        let noImageMimeTypes = ["video/h261",
                                "application/vnd.americandynamics.acc",
                                "application/x-ace-compressed",
                                "application/vnd.acucobol",
                                "application/internet-property-stream",
                                "audio/adpcm",
                                "application/pdf"]

        // When
        let areImages = noImageMimeTypes.map { MimeTypeUtils.isImage(mimeType: $0) }

        // Then
        areImages.forEach { XCTAssertFalse($0) }
    }

    func testIsImageFromMimeTypeWithOutImagesMimeTypes() {
        // Given
        let noImageMimeTypes = ["video/h261", "application/vnd.americandynamics.acc",
                                "application/x-ace-compressed", "application/vnd.acucobol",
                                "application/internet-property-stream", "audio/adpcm"]
        // When
        let areImages = noImageMimeTypes.map { MimeTypeUtils.isImage(mimeType: $0) }

        // Then
        areImages.forEach { XCTAssertFalse($0) }
    }
}
