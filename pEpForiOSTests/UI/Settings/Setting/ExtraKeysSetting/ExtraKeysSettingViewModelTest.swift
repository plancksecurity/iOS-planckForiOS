//
//  ExtraKeysSettingViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 21.08.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class ExtraKeysSettingViewModelTest: AccountDrivenTestBase {

    // MARK: - numRows

    func testSetup_noKeysDefined() {
        let testee = ExtraKeysSettingViewModel(delegate: nil)
        XCTAssertEqual(testee.numRows, 0)
    }

    func testNumRows_oneKeysDefined() {
        let numExtraKeysDefined = 1
        createAndSaveExtraKeys(numKeys: numExtraKeysDefined)
        let testee = ExtraKeysSettingViewModel(delegate: nil)
        XCTAssertEqual(testee.numRows, numExtraKeysDefined)
    }

    func testNumRows_multiKeysDefined() {
        let numExtraKeysDefined = 5
        createAndSaveExtraKeys(numKeys: numExtraKeysDefined)
        let testee = ExtraKeysSettingViewModel(delegate: nil)
        XCTAssertEqual(testee.numRows, numExtraKeysDefined)
    }

    // MARK: - subscript

    func testSubscript() {
        let numExtraKeysDefined = 5
        let definedFprs = createAndSaveExtraKeys(numKeys: numExtraKeysDefined).map { $0.fingerprint }
        let testee = ExtraKeysSettingViewModel(delegate: nil)
        for definedFpr in definedFprs {
            var fprContained = false
            for i in 0..<definedFprs.count {
                if testee[i] == definedFpr {
                    fprContained = true
                    break
                }
            }
            XCTAssertTrue(fprContained)
        }
    }

    // MARK: - store()

    func testStore_validFpr() {
        var numExtraKeysDefined = 1
        createAndSaveExtraKeys(numKeys: numExtraKeysDefined)
        XCTAssertEqual(ExtraKey.extraKeys().count, numExtraKeysDefined)

        let testee = ExtraKeysSettingViewModel(delegate: nil)
        let validFPR = UUID().uuidString
        XCTAssertNoThrow(testee.handleAddButtonPress(fpr: validFPR))
        numExtraKeysDefined += 1
        XCTAssertEqual(ExtraKey.extraKeys().count, numExtraKeysDefined)
    }

    func testStore_invalidFprShowsAlert() {
        let numExtraKeysDefined = 1
        createAndSaveExtraKeys(numKeys: numExtraKeysDefined)
        XCTAssertEqual(ExtraKey.extraKeys().count, numExtraKeysDefined)

        let expAlertShown = expectation(description: "expAlertShown")
        let delegate = TestDelegate(expectationShowFprInvalidAlert: expAlertShown)
        let testee = ExtraKeysSettingViewModel(delegate: delegate)
        let invalidFPR = "12345"
        testee.handleAddButtonPress(fpr: invalidFPR)
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    // MARK: - handleDeleteActionTriggered

    func testStorehandleDeleteActionTriggered() {
        let numExtraKeysDefined = 1
        createAndSaveExtraKeys(numKeys: numExtraKeysDefined)
        let testee = ExtraKeysSettingViewModel(delegate: nil)
        XCTAssertEqual(ExtraKey.extraKeys().count, numExtraKeysDefined)
        XCTAssertEqual(testee.numRows, numExtraKeysDefined)

        let expectedNumKeysAfterDeletion = numExtraKeysDefined - 1
        let idxOfOnlyFpr = 0
        testee.handleDeleteActionTriggered(for: idxOfOnlyFpr)
        XCTAssertEqual(ExtraKey.extraKeys().count, expectedNumKeysAfterDeletion)
        XCTAssertEqual(testee.numRows, expectedNumKeysAfterDeletion)

    }
}

// MARK: - HELPER

extension ExtraKeysSettingViewModelTest {

    /// MUST be used only on main queue.
    @discardableResult
    private func createAndSaveExtraKeys(numKeys: Int) -> [ExtraKey]{
        var createes = [ExtraKey]()
        for _ in 0..<numKeys {
            let createe = ExtraKey(withFpr: UUID().uuidString)
            createes.append(createe)
        }
        Session.main.commit()

        return createes
    }

    fileprivate class TestDelegate: ExtraKeysSettingViewModelDelegate {
        let expectationShowFprInvalidAlert: XCTestExpectation?

        init(expectationShowFprInvalidAlert: XCTestExpectation? = nil) {
            self.expectationShowFprInvalidAlert = expectationShowFprInvalidAlert
        }
        func showFprInvalidAlert() {
            if let exp = expectationShowFprInvalidAlert {
                exp.fulfill()
            } else {
                XCTFail("We do not expect this to be called")
            }
        }

        func refreshView() {
            fatalError()
        }
    }
}
