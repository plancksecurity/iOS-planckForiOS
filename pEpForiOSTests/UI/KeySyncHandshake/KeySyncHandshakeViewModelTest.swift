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
        keySyncHandshakeVM = KeySyncHandshakeViewModel()
        keySyncHandshakeVM?.delegate = self

        setDefaultActualState()
        expected = nil
    }

    override func tearDown() {
        unwrap(value: keySyncHandshakeVM)
        unwrap(value: actual)
        unwrap(value: expected)

        keySyncHandshakeVM = nil
        keySyncHandshakeVM?.delegate = nil
        actual = nil
        expected = nil
    }

    func didPressLanguageButtonTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallShowPicker: true)

        // WHEN
        keySyncHandshakeVM.didPressLanguageButton()

        // THEN
        assertExpectations()
    }

    func didSelectLanguageToOtherOrSameTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        //TODO: change when moc getter for handshake words
//        let expectedHandShakeWords = handShakeWords
        expected = State(didCallShowPicker: true, didCallToChangeLanaguage: true)

        // WHEN
        keySyncHandshakeVM.didSelect(language: "")

        // THEN
        assertExpectations()
    }

    func didSelectNoLanguageTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallClosePicker: true)

        // WHEN
        keySyncHandshakeVM.didSelect(language: nil)

        // THEN
        assertExpectations()
    }

    func didPressActionAcceptTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallDidPressAction: true, pressedAction: .accept)

        // WHEN
        keySyncHandshakeVM.didPress(action: .accept)

        // THEN
        assertExpectations()
    }

    func didPressActionDeclineTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallDidPressAction: true, pressedAction: .decline)

        // WHEN
        keySyncHandshakeVM.didPress(action: .decline)

        // THEN
        assertExpectations()
    }

    func didPressActionCancelTest() {
        // GIVEN
        let keySyncHandshakeVM = unwrap(value: self.keySyncHandshakeVM)
        expected = State(didCallDidPressAction: true, pressedAction: .cancel)

        // WHEN
        keySyncHandshakeVM.didPress(action: .cancel)

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
        actual?.didCallToChangeLanaguage = true
        actual?.didCallClosePicker = true
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

        XCTAssertEqual(expected, actual)
    }
}


// MARK: - Helper Structs
extension KeySyncHandshakeViewModelTest {
    struct State: Equatable {
        var didCallShowPicker: Bool
        var didCallClosePicker: Bool
        var didCallDidPressAction: Bool
        var didCallToChangeLanaguage: Bool

        var languagesToShow: [String]?
        var handShakeWords: String?
        var pressedAction: KeySyncHandshakeViewModel.Action?

        // Default value are default initial state
        init(didCallShowPicker: Bool = false, didCallClosePicker: Bool = false,
             didCallDidPressAction: Bool = false, didCallToChangeLanaguage: Bool = false,
             languagesToShow: [String] = [], handShakeWords: String = "",
             pressedAction: KeySyncHandshakeViewModel.Action? = nil) {

            self.didCallShowPicker = didCallShowPicker
            self.didCallClosePicker = didCallClosePicker
            self.didCallDidPressAction = didCallDidPressAction
            self.didCallToChangeLanaguage = didCallToChangeLanaguage

            self.languagesToShow = languagesToShow
            self.handShakeWords = handShakeWords
            self.pressedAction = pressedAction
        }
    }
}
