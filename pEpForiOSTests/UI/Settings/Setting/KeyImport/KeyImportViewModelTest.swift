//
//  KeyImportViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 18.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel
import pEpIOSToolbox

class KeyImportViewModelTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadKeys() {
        let documentsBrowser = DocumentsDirectoryBrowserMock(urls: [URL(fileURLWithPath: "file:///someFake")])
        let vm = KeyImportViewModel(documentsBrowser: documentsBrowser,
                                    keyImporter: KeyImporterMock())
    }
}

// MARK: - DocumentsDirectoryBrowserMock

class DocumentsDirectoryBrowserMock: DocumentsDirectoryBrowserProtocol {
    let urls: [URL]

    init(urls: [URL]) {
        self.urls = urls
    }

    func listFileUrls(fileTypes: [DocumentsDirectoryBrowserFileType]) throws -> [URL] {
        return urls
    }
}

// MARK: - KeyImporterMock

class KeyImporterMock: KeyImportUtilProtocol {
    func importKey(url: URL) throws -> KeyImportUtil.KeyData {
        throw KeyImportUtil.ImportError.cannotLoadKey
    }
    
    func setOwnKey(address: String, fingerprint: String) throws {
        throw KeyImportUtil.SetOwnKeyError.cannotSetOwnKey
    }
    

}
