//
//  SubjectCellViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class SubjectCellViewModelTest: XCTestCase {

    // MARK: - handleTextChanged

    func testHandleTextChanged_delegateInformed() {
        let initialContent = ""
        let changeContent = "changeContent"
        let resultDelegate =
            ResultDelegate(expDidChangeSubjectCalled: expDidChangeSubjectCalled(mustBeCalled: true),
                           expectedSubject: changeContent)
        let vm = SubjectCellViewModel(resultDelegate: resultDelegate)
        vm.content = initialContent
        vm.handleTextChanged(to: changeContent)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleTextChanged_delegateNotInformed() {
        let initialContent = ""
        let resultDelegate =
            ResultDelegate(expDidChangeSubjectCalled: expDidChangeSubjectCalled(mustBeCalled: false),
                           expectedSubject: nil)
        let vm = SubjectCellViewModel(resultDelegate: resultDelegate)
        vm.content = initialContent
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - shouldChangeText

    func testShouldChangeText_charsNotAllowed() {
        let charactersNotAllowedToTypeInSubject = Array("\n")
        assertShouldChangeText(testCharacters: charactersNotAllowedToTypeInSubject,
                               mustChangeText: false)
    }

    func testShouldChangeText_charsAllowed() {
        let charactersAllowedToTypeInSubject = Array("Aa !§$%&/()?`'ÄÖÜ*+üplöä\"@")
        assertShouldChangeText(testCharacters: charactersAllowedToTypeInSubject,
                               mustChangeText: true)
    }

    // MARK: - Helper

    private func assertShouldChangeText(initialContent: String? = nil,
                                testCharacters: [Character],
                                mustChangeText: Bool) {
        let initialContent = initialContent ?? ""
        let resultDelegate =
            ResultDelegate(expDidChangeSubjectCalled: expDidChangeSubjectCalled(mustBeCalled: false),
                           expectedSubject: nil)
        let vm = SubjectCellViewModel(resultDelegate: resultDelegate)
        vm.content = initialContent

        for char in testCharacters {
            let testee = String(char)
            let textChanged = vm.shouldChangeText(to: testee)
            if mustChangeText {
                XCTAssertTrue(textChanged)
            } else {
                XCTAssertFalse(textChanged)
            }
        }
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    private func expDidChangeSubjectCalled(mustBeCalled: Bool) -> XCTestExpectation {
        return expectation(inverted: !mustBeCalled)
    }

    class ResultDelegate: SubjectCellViewModelResultDelegate {
        let expDidChangeSubjectCalled: XCTestExpectation?
        let expectedSubject: String?

        init(expDidChangeSubjectCalled: XCTestExpectation?, expectedSubject: String?)  {
            self.expDidChangeSubjectCalled = expDidChangeSubjectCalled
            self.expectedSubject = expectedSubject
        }

        func subjectCellViewModelDidChangeSubject(_ vm: SubjectCellViewModel) {
            guard let exp = expDidChangeSubjectCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedSubject {
                XCTAssertEqual(vm.content, expected)
            }
        }
    }
}
