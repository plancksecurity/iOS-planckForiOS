//
//  KeySyncHandshakeViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
import PEPObjCAdapterFramework
@testable import pEpForiOS

final class KeySyncHandshakeViewModelTest: XCTestCase {

    var keySyncHandshakeVM: KeySyncHandshakeViewModel?
    var actual: State?
    var expected: State?

    override func setUp() {
        super.setUp()

        keySyncHandshakeVM = KeySyncHandshakeViewModel()
        keySyncHandshakeVM?.setFingerPrints(meFPR: "", partnerFPR: "", isNewGroup: true)
        keySyncHandshakeVM?.delegate = self

        setDefaultActualState()
        keySyncHandshakeVM?.completionHandler = { [weak self] action in
            self?.actual?.pressedAction = action
        }
        expected = nil
    }

    override func tearDown() {
        keySyncHandshakeVM?.delegate = nil
        keySyncHandshakeVM = nil
        actual = nil
        expected = nil

        super.tearDown()
    }

    func testDidPressActionAccept() {
        // GIVEN
        guard let keySyncHandshakeVM = keySyncHandshakeVM else {
            XCTFail()
            return
        }
        expected = State(pressedAction: .accept)

        // WHEN
        keySyncHandshakeVM.handle(action: .accept)

        // THEN
        assertExpectations()
    }

    func testDidPressActionDecline() {
        // GIVEN
        guard let keySyncHandshakeVM = keySyncHandshakeVM else {
            XCTFail()
            return
        }
        expected = State(pressedAction: .decline)

        // WHEN
        keySyncHandshakeVM.handle(action: .decline)

        // THEN
        assertExpectations()
    }

    func testDidPressActionCancel() {
        // GIVEN
        guard let keySyncHandshakeVM = keySyncHandshakeVM else {
            XCTFail()
            return
        }
        expected = State(pressedAction: .cancel)

        // WHEN
        keySyncHandshakeVM.handle(action: .cancel)

        // THEN
        assertExpectations()
    }
}

// MARK: - KeySyncHandshakeViewModelDelegate

extension KeySyncHandshakeViewModelTest: KeySyncHandshakeViewModelDelegate {
    func closePicker() {
        actual?.didCallClosePicker = true
    }

    func showPicker(withLanguages languages: [String], selectedLanguageIndex: Int?) {
        actual?.didCallShowPicker = true
        actual?.languagesToShow = languages
        actual?.selectedLanguageIndex = selectedLanguageIndex
    }

    func change(handshakeWordsTo: String) {
        actual?.didCallToUpdateTrustedWords = true
        actual?.fullWordsVersion = keySyncHandshakeVM?.fullTrustWords
    }
}

// MARK: - Private

extension KeySyncHandshakeViewModelTest {
    private func setDefaultActualState() {
        actual = State()
    }

    private func assertExpectations() {
        guard let expected = expected,
            let actual = actual else {
                XCTFail()
                return
        }

        //bools
        XCTAssertEqual(expected.didCallShowPicker, actual.didCallShowPicker)
        XCTAssertEqual(expected.didCallClosePicker, actual.didCallClosePicker)
        XCTAssertEqual(expected.didCallToUpdateTrustedWords, actual.didCallToUpdateTrustedWords)

        //values
        XCTAssertEqual(expected.fullWordsVersion, actual.fullWordsVersion)
        XCTAssertEqual(expected.languagesToShow, actual.languagesToShow)
        XCTAssertEqual(expected.selectedLanguageIndex, actual.selectedLanguageIndex)
        XCTAssertEqual(expected.handShakeWords, actual.handShakeWords)
        XCTAssertEqual(expected.pressedAction, actual.pressedAction)

        //In case some if missing or added but not checked
        XCTAssertEqual(expected, actual)
    }

    private func pEpSessionMocLanaguages() -> [PEPLanguage] {
        var languages = [PEPLanguage]()

        let expHaveLanguages = expectation(description: "expHaveLanguages")
        PEPSession().languageList({ error in
            XCTFail()
            expHaveLanguages.fulfill()
        }) { langs in
            languages = langs
            expHaveLanguages.fulfill()
        }
        wait(for: [expHaveLanguages], timeout: TestUtil.waitTime)

        return languages
    }
}


// MARK: - Helper Structs

extension KeySyncHandshakeViewModelTest {
    struct State: Equatable {
        var didCallShowPicker: Bool
        var didCallClosePicker: Bool
        var didCallToUpdateTrustedWords: Bool

        var fullWordsVersion: Bool?
        var languagesToShow: [String]?
        var selectedLanguageIndex: Int?
        var handShakeWords: String?
        var pressedAction: KeySyncHandshakeViewController.Action?

        // Default value are default initial state
        init(didCallShowPicker: Bool = false,
             didCallClosePicker: Bool = false,
             didCallToUpdateTrustedWords: Bool = false,
             fullWordsVersion: Bool = false,
             languagesToShow: [String] = [],
             selectedLanguageIndex: Int? = nil,
             handShakeWords: String = "",
             pressedAction: KeySyncHandshakeViewController.Action? = nil) {

            self.didCallShowPicker = didCallShowPicker
            self.didCallClosePicker = didCallClosePicker
            self.didCallToUpdateTrustedWords = didCallToUpdateTrustedWords

            self.fullWordsVersion = fullWordsVersion
            self.languagesToShow = languagesToShow
            self.selectedLanguageIndex = selectedLanguageIndex
            self.handShakeWords = handShakeWords
            self.pressedAction = pressedAction
        }
    }
}
