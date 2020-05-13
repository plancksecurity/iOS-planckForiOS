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
}
