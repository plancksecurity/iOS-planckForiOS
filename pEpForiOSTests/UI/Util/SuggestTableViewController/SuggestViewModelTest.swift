//
//  SuggestViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 02.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class SuggestViewModelTest: AccountDrivenTestBase {
    static let defaultNumExistingContacts = 5
    var existingIdentities = [Identity]()
    var fromIdentity: Identity?
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
        assertResults(for: searchTerm, numExpectedResults: 0)
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

    // MARK: - Helper

    private func setupContacts(numContacts: Int = SuggestViewModelTest.defaultNumExistingContacts) {
        existingIdentities = []
        for i in 0...numContacts {
            let id = Identity(address: "email\(i)@pep.security",
                userID: "\(i)",
                addressBookID: nil,
                userName: "id\(i)")
            existingIdentities.append(id)
            id.session.commit()
        }
        fromIdentity = existingIdentities[0]
        existingIdentities.remove(at: 0)
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
                               expectedSelection: Identity? = nil,
                               didToggleVisibilityMustBeCalled: Bool? = nil,
                               expectedDidToggleVisibilityToValue: Bool? = nil) {
        var expectationDidSelectCalled: XCTestExpectation? = nil
        var shouldCallDidSelectContact = false
        if expectedSelection != nil {
            expectationDidSelectCalled = expectation(description: "expectationDidSelectCalled")
            shouldCallDidSelectContact = true
        }
        let expectationDidResetCalled = expectation(description: "expectationDidResetCalled")
        if numExpectedResults > 0 {
            // If there are contacts in the DB already, SuggestViewModel fires 2 times
            expectationDidResetCalled.expectedFulfillmentCount = 2
        }

        var expectationDidToggleVisibilityToCalled: XCTestExpectation? = nil
        if let mustBeCalled = didToggleVisibilityMustBeCalled {
             expectationDidToggleVisibilityToCalled =
                expectation(description: "expectationDidToggleVisibilityToCalled")
                expectationDidToggleVisibilityToCalled?.isInverted = !mustBeCalled
        }
        let testResultDelegate =
            TestResultDelegate(
                shouldCallDidSelectContact: shouldCallDidSelectContact,
                expectedSelection: expectedSelection,
                expectationDidSelectCalled: expectationDidSelectCalled,
                expectationDidToggleVisibilityToCalled: expectationDidToggleVisibilityToCalled,
                expectedDidToggleVisibilityToValue: expectedDidToggleVisibilityToValue)
        let shouldCallDidReset = true
        let testViewModelDelegate =
            TestViewModelDelegate(shouldCallDidReset: shouldCallDidReset,
                                  expectationDidResetCalled: expectationDidResetCalled)
        let vm = SuggestViewModel(from: fromIdentity)
        viewModel = vm
        vm.delegate = testViewModelDelegate
        vm.resultDelegate = testResultDelegate
        vm.updateSuggestion(searchString: searchTerm)
        XCTAssertEqual(vm.numRows, numExpectedResults)
        if let selectRow = simulateUserSelectedRow {
            vm.handleRowSelected(at: selectRow)
        }
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    /**
     Sorts an `[Identity]` into database/stored order, that is, the order they
     are stored in the database and would be returned in when using `Identity.all()`.
     Note the use of `lowercased()`: Stored `Identity`s have their addresses lower-cased,
     while self-created ones may not.
     */
    func dataBaseOrder(identities: [Identity]) -> [Identity] {
        var addressSet = Set<String>()
        for ident in identities {
            let lcAddress = ident.address.lowercased()
            addressSet = addressSet.union([lcAddress])
        }

        return Identity.all().filter {
            return addressSet.contains($0.address.lowercased())
        }
    }
}

// MARK: - SuggestViewModelResultDelegate

extension SuggestViewModelTest {

    class TestResultDelegate: SuggestViewModelResultDelegate {
        let shouldCallDidSelectContact: Bool
        let expectedSelection: Identity?
        let expectationDidSelectCalled: XCTestExpectation?

        let expectationDidToggleVisibilityToCalled: XCTestExpectation?
        let expectedDidToggleVisibilityToValue: Bool?

        init(shouldCallDidSelectContact: Bool = true,
             expectedSelection: Identity? = nil,
             expectationDidSelectCalled: XCTestExpectation? = nil,
             expectationDidToggleVisibilityToCalled: XCTestExpectation? = nil,
             expectedDidToggleVisibilityToValue: Bool? = nil) {
            self.shouldCallDidSelectContact = shouldCallDidSelectContact
            self.expectedSelection = expectedSelection
            self.expectationDidSelectCalled = expectationDidSelectCalled
            self.expectationDidToggleVisibilityToCalled = expectationDidToggleVisibilityToCalled
            self.expectedDidToggleVisibilityToValue = expectedDidToggleVisibilityToValue
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

        func suggestViewModel(_ vm: SuggestViewModel, didToggleVisibilityTo newValue: Bool) {
            guard let exp = expectationDidToggleVisibilityToCalled else {
                // We are not interested in whether or not this delegtae is called.
                return
            }
            exp.fulfill()
            if let expValue = expectedDidToggleVisibilityToValue {
                XCTAssertEqual(newValue, expValue)
            }
        }
    }
}

// MARK: - SuggestViewModelDelegate

extension SuggestViewModelTest {

    class TestViewModelDelegate: SuggestViewModelDelegate {
        let shouldCallDidReset: Bool
        let expectationDidResetCalled: XCTestExpectation?

        init(shouldCallDidReset: Bool = true,
             expectationDidResetCalled: XCTestExpectation? = nil) {
            self.shouldCallDidReset = shouldCallDidReset
            self.expectationDidResetCalled = expectationDidResetCalled
        }

        //  SuggestViewModelDelegate

        func suggestViewModelDidResetModel(showResults: Bool) {
            guard shouldCallDidReset else {
                XCTFail("Should not be called")
                return
            }
            expectationDidResetCalled?.fulfill()
        }
    }
}
