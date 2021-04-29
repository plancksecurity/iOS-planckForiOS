//
//  KeyImportViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 18.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel
import pEpIOSToolbox

class KeyImportViewModelTest: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadRows() {
        let fileUrls = [URL(fileURLWithPath: "file:///someFake")]

        let documentsBrowser = DocumentsDirectoryBrowserMock(urls: fileUrls)
        let vm = KeyImportViewModel(documentsBrowser: documentsBrowser,
                                    keyImporter: KeyImporterMock())

        let rowsLoadedExpectation = expectation(description: "rowsLoadedExpectation")
        let delegate = KeyImportViewModelDelegateMock(rowsLoadedExpectation: rowsLoadedExpectation)
        vm.delegate = delegate

        vm.loadRows()

        wait(for: [rowsLoadedExpectation], timeout: TestUtil.waitTimeLocal)

        XCTAssertEqual(vm.rows.count, fileUrls.count)
        var rowIndex = 0
        for row in vm.rows {
            XCTAssertEqual(row.fileName, fileUrls[rowIndex].fileName())
            rowIndex = rowIndex + 1
        }
    }

    func testImportNoneKey() {
        let keyImporter = KeyImporterMock(importKeyErrorToThrow: .cannotLoadKey,
                                          importKeyDatas: [])

        let documentsBrowser = DocumentsDirectoryBrowserMock(urls: [URL(fileURLWithPath: "file:///someFake")])
        let vm = KeyImportViewModel(documentsBrowser: documentsBrowser,
                                    keyImporter: keyImporter)

        let showErrorExpectation = expectation(description: "showErrorExpectation")

        let rowsLoadedExpectation = expectation(description: "rowsLoadedExpectation")
        let delegate = KeyImportViewModelDelegateMock(rowsLoadedExpectation: rowsLoadedExpectation,
                                                      showErrorExpectation: showErrorExpectation)
        vm.delegate = delegate

        vm.loadRows()

        wait(for: [rowsLoadedExpectation], timeout: TestUtil.waitTimeLocal)

        vm.handleDidSelect(rowAt: IndexPath(row: 0, section: 0))

        wait(for: [showErrorExpectation], timeout: TestUtil.waitTimeLocal)
    }

    func testImportKey() {
        let vm = setupKeyImportViewModel()

        let showConfirmSetOwnKeyExpectation = expectation(description: "showConfirmSetOwnKeyExpectation")

        let rowsLoadedExpectation = expectation(description: "rowsLoadedExpectation")
        let delegate = KeyImportViewModelDelegateMock(rowsLoadedExpectation: rowsLoadedExpectation,
                                                      showErrorExpectation: nil,
                                                      showConfirmSetOwnKeyExpectation: showConfirmSetOwnKeyExpectation)
        vm.delegate = delegate

        vm.loadRows()

        wait(for: [rowsLoadedExpectation], timeout: TestUtil.waitTimeLocal)

        vm.handleDidSelect(rowAt: IndexPath(row: 0, section: 0))

        wait(for: [showConfirmSetOwnKeyExpectation], timeout: TestUtil.waitTimeLocal)
    }

    func testSetOwnKeyError() {
        let keyData = KeyImportUtil.KeyData(address: "address",
                                            fingerprint: "fpr",
                                            userName: "username")
        let keyImporter = KeyImporterMock(importKeyErrorToThrow: nil,
                                          importKeyDatas: [keyData],
                                          setOwnKeyErrorToThrow: KeyImportUtil.SetOwnKeyError.noMatchingAccount)

        let documentsBrowser = DocumentsDirectoryBrowserMock(urls: [URL(fileURLWithPath: "file:///someFake")])
        let vm = KeyImportViewModel(documentsBrowser: documentsBrowser,
                                    keyImporter: keyImporter)

        let showErrorExpectation = expectation(description: "showErrorExpectation")
        let delegate = KeyImportViewModelDelegateMock(rowsLoadedExpectation: nil,
                                                      showErrorExpectation: showErrorExpectation,
                                                      showConfirmSetOwnKeyExpectation: nil,
                                                      showSetOwnKeySuccessExpectation: nil)
        vm.delegate = delegate

        vm.handleUserConfirmedSetOwnKeys(keys: [KeyImportViewModel.KeyDetails(address: "address",
                                                                              fingerprint: "fingerprint",
                                                                              userName: "username")])

        wait(for: [showErrorExpectation], timeout: TestUtil.waitTimeLocal)
    }

    func testSetOwnKeySuccess() {
        let vm = setupKeyImportViewModel()

        let showSetOwnKeySuccessExpectation = expectation(description: "showSetOwnKeySuccessExpectation")
        let delegate = KeyImportViewModelDelegateMock(rowsLoadedExpectation: nil,
                                                      showErrorExpectation: nil,
                                                      showConfirmSetOwnKeyExpectation: nil,
                                                      showSetOwnKeySuccessExpectation: showSetOwnKeySuccessExpectation)
        vm.delegate = delegate

        vm.handleUserConfirmedSetOwnKeys(keys: [KeyImportViewModel.KeyDetails(address: "address",
                                                                              fingerprint: "fingerprint",
                                                                              userName: "username")])

        wait(for: [showSetOwnKeySuccessExpectation], timeout: TestUtil.waitTimeLocal)
    }

    func testUserPresentableFingerprint() {
        let vm = setupKeyImportViewModel()

        // Repeat with random values a couple of times
        for _ in 0 ... 100 {
            var fprIn = "" // the original value without spaces
            var fprExpected = "" // the expected value, formatted with spaces

            // Build a fingerprint, both the input, as the expected one
            for i in  1...10 {
                let randomQuadruple = randomCapitalizedString(length: 4)
                fprIn += randomQuadruple
                if i > 1 {
                    if i == 6 {
                        fprExpected += "\n"
                    } else {
                        fprExpected += " "
                    }
                }
                fprExpected += randomQuadruple
            }

            let keyDetail = KeyImportViewModel.KeyDetails(address: "address",
                                                          fingerprint: fprIn,
                                                          userName: "username")

            // Test the result
            let fprValue = vm.userPresentableFingerprint(keyDetails: [keyDetail])
            XCTAssertEqual(fprValue, fprExpected)
        }
    }
}

extension KeyImportViewModelTest {
    /// Create a `KeyImportViewModel` for simple tests that don't care much about the underlying data.
    func setupKeyImportViewModel() -> KeyImportViewModel {
        let keyData = KeyImportUtil.KeyData(address: "address",
                                            fingerprint: "fpr",
                                            userName: "username")
        let keyImporter = KeyImporterMock(importKeyErrorToThrow: nil,
                                          importKeyDatas: [keyData])

        let documentsBrowser = DocumentsDirectoryBrowserMock(urls: [URL(fileURLWithPath: "file:///someFake")])
        return KeyImportViewModel(documentsBrowser: documentsBrowser,
                                  keyImporter: keyImporter)

    }

    func randomCapitalizedString(length: Int) -> String {
        let letters : NSString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let len = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
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
    let importKeyErrorToThrow: KeyImportUtil.ImportError?
    let importKeyDatas: [KeyImportUtil.KeyData]
    let setOwnKeyErrorToThrow: KeyImportUtil.SetOwnKeyError?

    init(importKeyErrorToThrow: KeyImportUtil.ImportError? = nil,
         importKeyDatas: [KeyImportUtil.KeyData] = [],
         setOwnKeyErrorToThrow: KeyImportUtil.SetOwnKeyError? = nil) {
        self.importKeyErrorToThrow = importKeyErrorToThrow
        self.importKeyDatas = importKeyDatas
        self.setOwnKeyErrorToThrow = setOwnKeyErrorToThrow
    }

    func importKey(url: URL,
                   errorCallback: (Error) -> (),
                   completion: ([KeyImportUtil.KeyData]) -> ()) {
        if !importKeyDatas.isEmpty {
            return completion(importKeyDatas)
        } else if let theImportError = importKeyErrorToThrow {
            errorCallback(theImportError)
        } else {
            errorCallback(KeyImportUtil.ImportError.cannotLoadKey)
        }
    }

    func setOwnKey(userName: String,
                   address: String,
                   fingerprint: String,
                   errorCallback: @escaping (Error) -> (),
                   callback: @escaping () -> ()) {
        if let err = setOwnKeyErrorToThrow {
            errorCallback(err)
        } else {
            callback()
        }
    }
}

// MARK: - KeyImportViewModelDelegateMock

class KeyImportViewModelDelegateMock: KeyImportViewModelDelegate {
    let rowsLoadedExpectation: XCTestExpectation?
    let showErrorExpectation: XCTestExpectation?
    let showConfirmSetOwnKeyExpectation: XCTestExpectation?
    let showSetOwnKeySuccessExpectation: XCTestExpectation?

    init(rowsLoadedExpectation: XCTestExpectation? = nil,
         showErrorExpectation: XCTestExpectation? = nil,
         showConfirmSetOwnKeyExpectation: XCTestExpectation? = nil,
         showSetOwnKeySuccessExpectation: XCTestExpectation? = nil) {
        self.rowsLoadedExpectation = rowsLoadedExpectation
        self.showErrorExpectation = showErrorExpectation
        self.showConfirmSetOwnKeyExpectation = showConfirmSetOwnKeyExpectation
        self.showSetOwnKeySuccessExpectation = showSetOwnKeySuccessExpectation
    }

    func rowsLoaded() {
        if let exp = rowsLoadedExpectation {
            exp.fulfill()
        }
    }

    func showConfirmSetOwnKey(keys: [KeyImportViewModel.KeyDetails]) {
        if let exp = showConfirmSetOwnKeyExpectation {
            exp.fulfill()
        }
    }

    func showError(message: String) {
        if let exp = showErrorExpectation {
            exp.fulfill()
        }
    }

    func showSetOwnKeySuccess() {
        if let exp = showSetOwnKeySuccessExpectation {
            exp.fulfill()
        }
    }
}
