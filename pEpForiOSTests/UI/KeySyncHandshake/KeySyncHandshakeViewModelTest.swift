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
        keySyncHandshakeVM = KeySyncHandshakeViewModel(pEpSession: PEPSessionMoc())
        keySyncHandshakeVM?.fingerPrints(meFPR: "", partnerFPR: "")
        keySyncHandshakeVM?.delegate = self

        setDefaultActualState()
        expected = nil
    }

    override func tearDown() {
        unwrap(value: keySyncHandshakeVM)
        unwrap(value: actual)
        unwrap(value: expected)

        keySyncHandshakeVM?.delegate = nil
        keySyncHandshakeVM = nil
        actual = nil
        expected = nil
    }

    func testDidSelectLanguageToOtherOrSame() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallClosePicker: true, didCallToUpdateTrustedWords: true)

        // WHEN
        keySyncHandshakeVM.didSelect(languageRow: 0)

        // THEN
        assertExpectations()
    }

    func testDidPressActionAccept() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallDidPressAction: true, pressedAction: .accept)

        // WHEN
        keySyncHandshakeVM.didPress(action: .accept)

        // THEN
        assertExpectations()
    }

    func testDidPressActionChangeLanguage() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallShowPicker: true, languagesToShow: ["", ""])

        // WHEN
        keySyncHandshakeVM.didPress(action: .changeLanguage)

        // THEN
        assertExpectations()
    }

    func testDidPressActionDecline() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallDidPressAction: true, pressedAction: .decline)

        // WHEN
        keySyncHandshakeVM.didPress(action: .decline)

        // THEN
        assertExpectations()
    }

    func testDidPressActionCancel() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallDidPressAction: true, pressedAction: .cancel)

        // WHEN
        keySyncHandshakeVM.didPress(action: .cancel)

        // THEN
        assertExpectations()
    }

    func testDidLongPressWords() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
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
    @discardableResult
    private func unwrap<T>(value: T?) -> T {
        guard let value = value else {
            XCTFail()
            fatalError("value is nil")
        }
        return value
    }

    private func setDefaultActualState() {
        actual = State()
    }

    private func assertExpectations() {
        let expected = unwrap(value: self.expected)
        let actual = unwrap(value: self.actual)

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
