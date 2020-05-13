//
//  FileBrowserTest.swift
//  pEpIOSToolboxTests
//
//  Created by Dirk Zimmermann on 13.05.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import XCTest

import pEpIOSToolbox

class FileBrowserTest: XCTestCase {

    override func setUpWithError() throws {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        for pathUrl in urls {
            try FileManager.default.createDirectory(at: pathUrl,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
    }

    override func tearDownWithError() throws {
    }

    func testNoFiles() throws {
        let urls = try FileBrowser.listFileUrls(fileTypes: [.key])
        XCTAssertTrue(urls.isEmpty)
    }

    func test1Key() throws {
        try createTestfile(fileType: .key)
        let urls = try FileBrowser.listFileUrls(fileTypes: [.key])
        XCTAssertFalse(urls.isEmpty)
    }

    // MARK: - Private

    private func createTestfile(fileType: FileBrowser.FileType) throws {
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
