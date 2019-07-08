//
//  KeySyncHandshakeViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 05/07/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import pEpForiOS

class KeySyncHandshakeViewModelTest: XCTestCase {

    var keySyncHandshakeVM: KeySyncHandshakeViewModel?

    var didCallShowPicker = false
    var didCallClosePicker = false
    var didCallDidPressAction = false
    var didCallToChangeLanaguage = false

    var languagesToShow: [String] = []
    var handShakeWords: String = ""
    var pressedAction: KeySyncHandshakeViewModel.Action?


    override func setUp() {
        keySyncHandshakeVM = KeySyncHandshakeViewModel()
        keySyncHandshakeVM?.delegate = self

        didCallShowPicker = false
        didCallClosePicker = false
        didCallDidPressAction = false
        didCallToChangeLanaguage = false

        languagesToShow = []
        handShakeWords = ""
        pressedAction = nil
    }

    override func tearDown() {
        keySyncHandshakeVM = nil
        keySyncHandshakeVM?.delegate = nil
    }

    func didPressLanguageButtonTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(keysyncHandShakeVM: self.keySyncHandshakeVM)
        let expectedHandShakeWords = handShakeWords
        let expectedPressedAction = pressedAction
        let expectedLanguagesToShow = languagesToShow

        // WHEN
        keySyncHandshakeVM.didPressLanguageButton()

        // THEN
        XCTAssertTrue(didCallShowPicker)

        XCTAssertFalse(didCallClosePicker)
        XCTAssertFalse(didCallToChangeLanaguage)
        XCTAssertFalse(didCallDidPressAction)
        XCTAssertEqual(expectedHandShakeWords, handShakeWords)
        XCTAssertEqual(expectedPressedAction, pressedAction)
        XCTAssertEqual(expectedLanguagesToShow, languagesToShow)

    }

    func didSelectLanguageToOtherOrSameTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(keysyncHandShakeVM: self.keySyncHandshakeVM)
        //TODO: change when moc getter for handshake words
//        let expectedHandShakeWords = handShakeWords
        let expectedPressedAction = pressedAction
        let expectedLanguagesToShow = languagesToShow

        // WHEN
        keySyncHandshakeVM.didSelect(language: "")

        // THEN
        XCTAssertTrue(didCallClosePicker)
        XCTAssertTrue(didCallToChangeLanaguage)
//        XCTAssertEqual(expectedHandShakeWords, handShakeWords)

        XCTAssertFalse(didCallShowPicker)
        XCTAssertFalse(didCallDidPressAction)
        XCTAssertEqual(expectedPressedAction, pressedAction)
        XCTAssertEqual(expectedLanguagesToShow, languagesToShow)
    }

    func didSelectNoLanguageTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(keysyncHandShakeVM: self.keySyncHandshakeVM)
        let expectedHandShakeWords = handShakeWords
        let expectedPressedAction = pressedAction
        let expectedLanguagesToShow = languagesToShow

        // WHEN
        keySyncHandshakeVM.didSelect(language: nil)

        // THEN
        XCTAssertTrue(didCallClosePicker)

        XCTAssertFalse(didCallToChangeLanaguage)
        XCTAssertFalse(didCallShowPicker)
        XCTAssertFalse(didCallDidPressAction)
        XCTAssertEqual(expectedHandShakeWords, handShakeWords)
        XCTAssertEqual(expectedPressedAction, pressedAction)
        XCTAssertEqual(expectedLanguagesToShow, languagesToShow)
    }

    func didPressActionAcceptTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(keysyncHandShakeVM: self.keySyncHandshakeVM)
        let expectedPressedAction = KeySyncHandshakeViewModel.Action.accept
        let expectedHandShakeWords = handShakeWords
        let expectedLanguagesToShow = languagesToShow

        // WHEN
        keySyncHandshakeVM.didPress(action: .accept)

        // THEN
        XCTAssertTrue(didCallDidPressAction)
        XCTAssertEqual(expectedPressedAction, pressedAction)

        XCTAssertFalse(didCallShowPicker)
        XCTAssertFalse(didCallClosePicker)
        XCTAssertFalse(didCallToChangeLanaguage)
        XCTAssertEqual(expectedHandShakeWords, handShakeWords)
        XCTAssertEqual(expectedLanguagesToShow, languagesToShow)
    }

    func didPressActionDeclineTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(keysyncHandShakeVM: self.keySyncHandshakeVM)
        let expectedPressedAction = KeySyncHandshakeViewModel.Action.decline
        let expectedHandShakeWords = handShakeWords
        let expectedLanguagesToShow = languagesToShow

        // WHEN
        keySyncHandshakeVM.didPress(action: .decline)

        // THEN
        XCTAssertTrue(didCallDidPressAction)
        XCTAssertEqual(expectedPressedAction, pressedAction)

        XCTAssertFalse(didCallShowPicker)
        XCTAssertFalse(didCallClosePicker)
        XCTAssertFalse(didCallToChangeLanaguage)
        XCTAssertEqual(expectedHandShakeWords, handShakeWords)
        XCTAssertEqual(expectedLanguagesToShow, languagesToShow)
    }

    func didPressActionCancelTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(keysyncHandShakeVM: self.keySyncHandshakeVM)
        let expectedPressedAction = KeySyncHandshakeViewModel.Action.cancel
        let expectedHandShakeWords = handShakeWords
        let expectedLanguagesToShow = languagesToShow

        // WHEN
        keySyncHandshakeVM.didPress(action: .cancel)

        // THEN
        XCTAssertTrue(didCallDidPressAction)
        XCTAssertEqual(expectedPressedAction, pressedAction)

        XCTAssertFalse(didCallShowPicker)
        XCTAssertFalse(didCallClosePicker)
        XCTAssertFalse(didCallToChangeLanaguage)
        XCTAssertEqual(expectedHandShakeWords, handShakeWords)
        XCTAssertEqual(expectedLanguagesToShow, languagesToShow)
    }
}

// MARK: - KeySyncHandshakeViewModelDelegate

extension KeySyncHandshakeViewModelTest: KeySyncHandshakeViewModelDelegate {
    func closePicker() {
        didCallClosePicker = true
    }

    func didPress(action: KeySyncHandshakeViewModel.Action) {
        didCallDidPressAction = true
        pressedAction = action
    }

    func showPicker(withLanguages languages: [String]) {
        didCallShowPicker = true
        languagesToShow = languages
    }

    func change(handshakeWordsTo: String) {
        didCallToChangeLanaguage = true
        didCallClosePicker = true
    }
}

// MARK: - Private

extension KeySyncHandshakeViewModelTest {
    func unwrap(keysyncHandShakeVM: KeySyncHandshakeViewModel?) -> KeySyncHandshakeViewModel {
        guard let keysyncHandShakeVM = keysyncHandShakeVM else {
            XCTFail()
            fatalError("keysyncHandShakeVM is nil")
        }
        return keysyncHandShakeVM
    }
}
