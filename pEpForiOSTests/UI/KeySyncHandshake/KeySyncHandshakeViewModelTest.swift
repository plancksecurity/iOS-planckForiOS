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
        expected = State(didCallDissmissView: true, pressedAction: .accept)

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
        expected = State(didCallDissmissView: true, pressedAction: .decline)

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
        expected = State(didCallDissmissView: true, pressedAction: .cancel)

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
    func dissmissView() {
        actual?.didCallDissmissView = true
    }

    func closePicker() {
        actual?.didCallClosePicker = true
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
        XCTAssertEqual(expected.didCallDissmissView, actual.didCallDissmissView)
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
        var didCallDissmissView: Bool
        var didCallToUpdateTrustedWords: Bool

        var fullWordsVersion: Bool?
        var languagesToShow: [String]?
        var handShakeWords: String?
        var pressedAction: KeySyncHandshakeViewController.Action?

        // Default value are default initial state
        init(didCallShowPicker: Bool = false,
             didCallClosePicker: Bool = false,
             didCallDissmissView: Bool = false,
             didCallToUpdateTrustedWords: Bool = false,
             fullWordsVersion: Bool = false,
             languagesToShow: [String] = [],
             handShakeWords: String = "",
             pressedAction: KeySyncHandshakeViewController.Action? = nil) {

            self.didCallShowPicker = didCallShowPicker
            self.didCallClosePicker = didCallClosePicker
            self.didCallDissmissView = didCallDissmissView
            self.didCallToUpdateTrustedWords = didCallToUpdateTrustedWords

            self.fullWordsVersion = fullWordsVersion
            self.languagesToShow = languagesToShow
            self.handShakeWords = handShakeWords
            self.pressedAction = pressedAction
        }
    }
}
