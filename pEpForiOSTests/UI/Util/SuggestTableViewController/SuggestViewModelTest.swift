//
//  SuggestViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 02.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class SuggestViewModelTest: CoreDataDrivenTestBase {
    static let defaultNumExistingContacts = 5
    var existingIdentities = [Identity]()
    var viewModel: SuggestViewModel?

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        setupContacts()
    }

    // MARK: - Suggestions Tests

    func testSearchTermNotEmpty() {
        let searchTerm = "security"
        assertResults(for: searchTerm,
                      numExpectedResults: SuggestViewModelTest.defaultNumExistingContacts)
    }

    func testSearchTermEmpty() {
        let searchTerm = ""
        assertResults(for: searchTerm, numExpectedResults: 0)
    }

    func testSearchTermNotEnoughChars_oneChar() {
        let searchTerm = "i"
        assertResults(for: searchTerm,  numExpectedResults: 0)
    }

    func testSearchTermNotEnoughChars_twoChars() {
        let searchTerm = "id"
        assertResults(for: searchTerm, numExpectedResults: 0)
    }

    func testSearchTermJustEnoughChars_threeChars() {
        let searchTerm = "id1"
        assertResults(for: searchTerm, numExpectedResults: 1)
    }

    func testFindOne_byUserName() {
        guard let id = existingIdentities.first,
        let searchTerm = id.userName else {
            XCTFail("No ID")
            return
        }
        assertResults(for: searchTerm, numExpectedResults: 1)
    }

    func testFindOne_byEmail() {
        guard let id = existingIdentities.first else {
                XCTFail("No ID")
                return
        }
        let searchTerm = id.address

        assertResults(for: searchTerm, numExpectedResults: 1)
    }

    func testNonExisting() {
        let searchTerm = "aTermThatIsNotContained"
        assertResults(for: searchTerm, numExpectedResults: 0)
    }

    // MARK: - User Action Tests

    func testUserSelection_oneExists() {
        let numSuggestionsExpected = 1
        let selectRow = numSuggestionsExpected - 1
        let existing = Identity(address: "testUserSelection@oneExists.security")
        existing.save()
        existingIdentities = [existing]
        assertResults(for: existing.address,
                      simulateUserSelectedRow: selectRow,
                      numExpectedResults: numSuggestionsExpected,
                      expectedSelection: existing)
    }

    func testUserSelection_selectLast() {
        let numSuggestionsExpected = 2
        let selectRow = numSuggestionsExpected - 1
        let common = "testUserSelection@oneExists.security"
        let existing1 = Identity(address: "\(common)1")
        existing1.save()
        let existing2 = Identity(address: "\(common)2")
        existing2.save()
        existingIdentities = [existing1, existing2]
        assertResults(for: common,
                      simulateUserSelectedRow: selectRow,
                      numExpectedResults: numSuggestionsExpected,
                      expectedSelection: existing2)
    }

    func testUserSelection_selectFirst() {
        let numSuggestionsExpected = 2
        let selectRow = 0
        let common = "testUserSelection@oneExists.security"
        let existing1 = Identity(address: "\(common)1")
        existing1.save()
        let existing2 = Identity(address: "\(common)2")
        existing2.save()
        existingIdentities = [existing1, existing2]
        assertResults(for: common,
                      simulateUserSelectedRow: selectRow,
                      numExpectedResults: numSuggestionsExpected,
                      expectedSelection: existing1)
    }

    // MARK: - Helper

    private func setupContacts(numContacts: Int = SuggestViewModelTest.defaultNumExistingContacts) {
        existingIdentities = []
        for i in 1...numContacts {
            let id = Identity(address: "email\(i)@pep.security",
                userID: nil,
                addressBookID: nil,
                userName: "id\(i)",
                isMySelf: false)
            id.save()
            existingIdentities.append(id)
        }
    }

    /// - Parameters:
    ///   - searchTerm: text to get suggestions for
    ///   - simulateUserSelectedRow: row num to simulate user selection for.
    ///                                 If nil, no user actions are simulated.
    ///   - numExpectedResults: epected number of suggestions
    ///   - expectedSelection: expected identity for simulated user selection
    private func assertResults(for searchTerm: String,
                               simulateUserSelectedRow: Int? = nil,
                               numExpectedResults: Int,
                               expectedSelection: Identity? = nil) {
        var expectationDidSelectCalled: XCTestExpectation? = nil
        var shouldCallDidSelectContact = false
        if expectedSelection != nil {
            expectationDidSelectCalled = expectation(description: "expectationDidSelectCalled")
            shouldCallDidSelectContact = true
        }
        let expectationDidResetCalled = expectation(description: "expectationDidResetCalled")
        let testResultDelegate =
            TestResultDelegate(shouldCallDidSelectContact: shouldCallDidSelectContact,
                               expectedSelection: expectedSelection,
                               expectationDidSelectCalled: expectationDidSelectCalled)
        let shouldCallDidReset = true
        let testViewModelDelegate =
            TestViewModelDelegate(shouldCallDidReset: shouldCallDidReset,
                                  expectationDidResetCalled: expectationDidResetCalled)
        let vm = SuggestViewModel(delegate: testViewModelDelegate)
        viewModel = vm
        vm.resultDelegate = testResultDelegate
        vm.updateSuggestion(searchString: searchTerm)
        XCTAssertEqual(vm.numRows, numExpectedResults)
        if let selectRow = simulateUserSelectedRow {
            vm.handleRowSelected(at: selectRow)
        }
        waitForExpectations(timeout: TestUtil.waitTime)
    }
}

// MARK: - SuggestViewModelDelegate

class TestViewModelDelegate: SuggestViewModelDelegate {
    let shouldCallDidReset: Bool
    let expectationDidResetCalled: XCTestExpectation?

    init(shouldCallDidReset: Bool = true,
         expectationDidResetCalled: XCTestExpectation? = nil) {
        self.shouldCallDidReset = shouldCallDidReset
        self.expectationDidResetCalled = expectationDidResetCalled
    }

    //  SuggestViewModelDelegate

    func suggestViewModelDidResetModel() {
        guard shouldCallDidReset else {
            XCTFail("Should not be called")
            return
        }
        expectationDidResetCalled?.fulfill()
    }
}

// MARK: - SuggestViewModelResultDelegate

class TestResultDelegate: SuggestViewModelResultDelegate {
    let shouldCallDidSelectContact: Bool
    let expectedSelection: Identity?
    let expectationDidSelectCalled: XCTestExpectation?

    init(shouldCallDidSelectContact: Bool = true,
         expectedSelection: Identity? = nil,
         expectationDidSelectCalled: XCTestExpectation? = nil) {
        self.shouldCallDidSelectContact = shouldCallDidSelectContact
        self.expectedSelection = expectedSelection
        self.expectationDidSelectCalled = expectationDidSelectCalled
    }

    // SuggestViewModelResultDelegate

    func suggestViewModelDidSelectContact(identity: Identity) {
        guard shouldCallDidSelectContact else {
            XCTFail("Should not be called")
            return
        }
        expectationDidSelectCalled?.fulfill()
        XCTAssertEqual(expectedSelection?.address.lowercased(),
                       identity.address.lowercased())
    }
}
