//
//  KeySyncHandshakeViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

final class KeySyncHandshakeViewModelTest: XCTestCase {

    var keySyncHandshakeVM: KeySyncHandshakeViewModel?
    var actual: State?
    var expected: State?

    override func setUp() {
        super.setUp()

        keySyncHandshakeVM = KeySyncHandshakeViewModel(pEpSession: PEPSessionMoc())
        keySyncHandshakeVM?.fingerPrints(meFPR: "", partnerFPR: "")
        keySyncHandshakeVM?.delegate = self

        setDefaultActualState()
        expected = nil
    }

    override func tearDown() {
        keySyncHandshakeVM?.delegate = nil
        keySyncHandshakeVM = nil
        actual = nil
        expected = nil

        super.tearDown()
    }

    func testDidSelectLanguageToOtherOrSame() {
        // GIVEN
        guard let keySyncHandshakeVM = keySyncHandshakeVM else {
            XCTFail()
            return
        }
        expected = State(didCallClosePicker: true, didCallToUpdateTrustedWords: true)

        // WHEN
        keySyncHandshakeVM.didSelect(languageRow: 0)

        // THEN
        assertExpectations()
    }

    func testDidPressActionAccept() {
        // GIVEN
        guard let keySyncHandshakeVM = keySyncHandshakeVM else {
            XCTFail()
            return
        }
        expected = State(didCallDidPressAction: true, pressedAction: .accept)

        // WHEN
        keySyncHandshakeVM.handle(action: .accept)

        // THEN
        assertExpectations()
    }

    func testDidPressActionChangeLanguage() {
        // GIVEN
        guard let keySyncHandshakeVM = keySyncHandshakeVM else {
            XCTFail()
            return
        }
        expected = State(didCallShowPicker: true, languagesToShow: ["", ""])

        // WHEN
        keySyncHandshakeVM.handle(action: .changeLanguage)

        // THEN
        assertExpectations()
    }

    func testDidPressActionDecline() {
        // GIVEN
        guard let keySyncHandshakeVM = keySyncHandshakeVM else {
            XCTFail()
            return
        }
        expected = State(didCallDidPressAction: true, pressedAction: .decline)

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
        expected = State(didCallDidPressAction: true, pressedAction: .cancel)

        // WHEN
        keySyncHandshakeVM.handle(action: .cancel)

        // THEN
        assertExpectations()
    }

    func testDidLongPressWords() {
        // GIVEN
        guard let keySyncHandshakeVM = keySyncHandshakeVM else {
            XCTFail()
            return
        }
        expected = State(didCallToUpdateTrustedWords: true, fullWordsVersion: true)

        // WHEN
        keySyncHandshakeVM.didLongPressWords()

        // THEN
        assertExpectations()
    }
}

// MARK: - KeySyncHandshakeViewModelDelegate

extension KeySyncHandshakeViewModelTest: KeySyncHandshakeViewModelDelegate {
    func closePicker() {
        actual?.didCallClosePicker = true
    }

    func didPress(action: KeySyncHandshakeViewModel.Action) {
        actual?.didCallDidPressAction = true
        actual?.pressedAction = action
    }

    func showPicker(withLanguages languages: [String]) {
        actual?.didCallShowPicker = true
        actual?.languagesToShow = languages
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
        XCTAssertEqual(expected.didCallDidPressAction, actual.didCallDidPressAction)
        XCTAssertEqual(expected.didCallToUpdateTrustedWords, actual.didCallToUpdateTrustedWords)

        //values
        XCTAssertEqual(expected.fullWordsVersion, actual.fullWordsVersion)
        XCTAssertEqual(expected.languagesToShow, actual.languagesToShow)
        XCTAssertEqual(expected.handShakeWords, actual.handShakeWords)
        XCTAssertEqual(expected.pressedAction, actual.pressedAction)

        //In case some if missing or added but not checked
        XCTAssertEqual(expected, actual)
    }
}


// MARK: - Helper Structs
extension KeySyncHandshakeViewModelTest {
    struct State: Equatable {
        var didCallShowPicker: Bool
        var didCallClosePicker: Bool
        var didCallDidPressAction: Bool
        var didCallToUpdateTrustedWords: Bool

        var fullWordsVersion: Bool?
        var languagesToShow: [String]?
        var handShakeWords: String?
        var pressedAction: KeySyncHandshakeViewModel.Action?

        // Default value are default initial state
        init(didCallShowPicker: Bool = false,
             didCallClosePicker: Bool = false,
             didCallDidPressAction: Bool = false,
             didCallToUpdateTrustedWords: Bool = false,
             fullWordsVersion: Bool = false,
             languagesToShow: [String] = [],
             handShakeWords: String = "",
             pressedAction: KeySyncHandshakeViewModel.Action? = nil) {

            self.didCallShowPicker = didCallShowPicker
            self.didCallClosePicker = didCallClosePicker
            self.didCallDidPressAction = didCallDidPressAction
            self.didCallToUpdateTrustedWords = didCallToUpdateTrustedWords

            self.fullWordsVersion = fullWordsVersion
            self.languagesToShow = languagesToShow
            self.handShakeWords = handShakeWords
            self.pressedAction = pressedAction
        }
    }
}
