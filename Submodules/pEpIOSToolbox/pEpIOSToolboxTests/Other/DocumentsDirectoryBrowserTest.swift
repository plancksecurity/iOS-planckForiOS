//
//  DocumentsDirectoryBrowserTest.swift
//  pEpIOSToolboxTests
//
//  Created by Dirk Zimmermann on 13.05.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import XCTest

import pEpIOSToolbox

class DocumentsDirectoryBrowserTest: XCTestCase {
    let documentsBrowser: DocumentsDirectoryBrowserProtocol = DocumentsDirectoryBrowser()

    override func setUpWithError() throws {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        for pathUrl in urls {
            try FileManager.default.createDirectory(at: pathUrl,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
    }

    override func tearDownWithError() throws {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        for pathUrl in urls {
            let files = try FileManager.default.contentsOfDirectory(at: pathUrl,
                                                                    includingPropertiesForKeys: nil,
                                                                    options: [])
            for deleteUrl in files {
                try FileManager.default.removeItem(at: deleteUrl)
            }
        }
    }

    func testNoFiles() throws {
        let urls = try documentsBrowser.listFileUrls(fileTypes: [.key])
        XCTAssertTrue(urls.isEmpty)
    }

    func test1Key() throws {
        try createTestfile(fileType: .key)
        let urls = try documentsBrowser.listFileUrls(fileTypes: [.key])
        XCTAssertFalse(urls.isEmpty)
    }

    // MARK: - Private

    private func createTestfile(fileType: DocumentsDirectoryBrowserFileType) throws {
        guard let url = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask).first else {
                                                    XCTFail()
                                                    return
        }

        guard let ext = fileType.fileExtensions().first else {
            XCTFail()
            return
        }

        let newUrl = url.appendingPathComponent("somefile",
                                                isDirectory: false).appendingPathExtension(ext)
        try Data(base64Encoded: "somedata")?.write(to: newUrl)
    }
}
