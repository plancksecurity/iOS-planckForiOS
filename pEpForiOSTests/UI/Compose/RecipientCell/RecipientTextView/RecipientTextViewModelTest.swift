//
//  RecipientTextViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 18.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class RecipientTextViewModelTest: CoreDataDrivenTestBase {
    var validId: Identity {
        return account.user
    }
    var vm = RecipientTextViewModel()
    var delegate: TestRecipientTextViewModelDelegate?
    var resultDelegate: TestRecipientTextViewModelResultDelegate?
    let randomText = "randomText"
    let randomAttributedText = NSAttributedString(string: "randomText")
    let emptyRange = NSRange(location: 0, length: 0)
    let emptyAttributedString = NSAttributedString(string: "")

    override func setUp() {
        super.setUp()
        vm = RecipientTextViewModel()
    }

    // MARK: - init(resultDelegate:

    func testInitWithResultDelegate() {
        let resultDelegate =
            TestRecipientTextViewModelResultDelegate(expectDidChangeRecipientsCalled: nil,
                                                     didChangeRecipients: nil,
                                                     expectDidEndEditingCalled: nil,
                                                     expectTextChangedCalled: nil,
                                                     textChanged: nil)
        let testeeVM = RecipientTextViewModel(resultDelegate: resultDelegate)
        XCTAssertNotNil(testeeVM.resultDelegate)
        XCTAssertTrue(testeeVM.resultDelegate === resultDelegate)
    }

    // MARK: - isAddressDeliminator

    func testIsAddressDeliminator_space() {
        let space = " "
        XCTAssertTrue(vm.isAddressDeliminator(str: space))
    }

    func testIsAddressDeliminator_nl() {
        let nl = "\n"
        XCTAssertTrue(vm.isAddressDeliminator(str: nl))
    }

    func testIsAddressDeliminator_no_tab() {
        let no = "\t"
        XCTAssertFalse(vm.isAddressDeliminator(str: no))
    }

    func testIsAddressDeliminator_no_empty() {
        let no = ""
        XCTAssertFalse(vm.isAddressDeliminator(str: no))
    }

    /*
     public func handleAddressDelimiterTyped(range: NSRange,
     of text: NSAttributedString) -> Bool {
     */
    // MARK: - add(recipient:)
    
    func testAddRecipientCalled() {
        assert(addRecipientValue: validId.address, ignoreCallsToAddRecipient: false)
        vm.add(recipient: validId)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testAddRecipientNotCalled() {
        assert(addRecipientValue: nil, ignoreCallsToAddRecipient: false)
        callAll(addRecipient: false)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - shouldInteract(WithTextAttachment:)

    func testSuppressDefaultLongPressMenu_yes() {
        let attachmentWithImage = RecipientTextViewTextAttachment(recipient: validId)
        attachmentWithImage.image = UIImage()
        let shouldInteract = vm.shouldInteract(WithTextAttachment: attachmentWithImage)
        XCTAssertFalse(shouldInteract)
    }

    func testSuppressDefaultLongPressMenu_no() {
        let attachmentWithoutImage = RecipientTextViewTextAttachment(recipient: validId)
        attachmentWithoutImage.image = nil
        let shouldInteract = vm.shouldInteract(WithTextAttachment: attachmentWithoutImage)
        XCTAssertTrue(shouldInteract)
    }

    // MARK: - handleDidEndEditing(range:text:)

    func testHandleDidEndEditing_noText() {
        assert(resultDelegateCalledDidChangeRecipients: nil,
               ignoreCallsResultDelegateCalledDidChangeRecipients: false,
               resultDelegateCalledDidEndEditingCalled: true,
               ignoreCallsresultDelegateCalledDidEndEditingCalled: false)
        vm.handleDidEndEditing(range: emptyRange, of: emptyAttributedString)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleDidEndEditing_noAddress() {
        assert(resultDelegateCalledDidChangeRecipients: nil,
               ignoreCallsResultDelegateCalledDidChangeRecipients: false,
               resultDelegateCalledDidEndEditingCalled: true,
               ignoreCallsresultDelegateCalledDidEndEditingCalled: false)
        vm.handleDidEndEditing(range: emptyRange, of: randomAttributedText)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleDidEndEditing_validAddress() {
        assert(resultDelegateCalledDidChangeRecipients: [validId],
               ignoreCallsResultDelegateCalledDidChangeRecipients: false,
               resultDelegateCalledDidEndEditingCalled: true,
               ignoreCallsresultDelegateCalledDidEndEditingCalled: false)
        let address = NSAttributedString(string: validId.address)
        vm.handleDidEndEditing(range: emptyRange, of: address)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleDidEndEditing_notCalledAsSideEffect() {
        assert(resultDelegateCalledDidChangeRecipients: nil,
               ignoreCallsResultDelegateCalledDidChangeRecipients: false,
               resultDelegateCalledDidEndEditingCalled: false,
               ignoreCallsresultDelegateCalledDidEndEditingCalled: false)
        callAll(handleDidEndEditing: false)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

// MARK: - handleTextChange

    func testHandleTextChange_called() {
        let text = randomText
        assert(resultDelegateCalledTextChanged: text,
               ignoreResultDelegateCalledTextChanged: false)
        vm.handleTextChange(newText: text)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleTextChange_notCalled() {
        assert(resultDelegateCalledTextChanged: nil,
               ignoreResultDelegateCalledTextChanged: false)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleTextChange_isDirty() {
        let text = randomText
        vm.handleTextChange(newText: text)
        XCTAssertTrue(vm.isDirty)
    }

    func testHandleTextChange_isNotDirty() {
        callAll(addRecipient: false, handleTextChange: false, handleAddressDelimiterTyped: false)
        XCTAssertFalse(vm.isDirty)
    }

    // MARK: - handleAddressDelimiterTyped(range:of text:)

    func testHandleAddressDelimiterTyped_validAddressOnly() {
        let identitiy = validId
        let text = validId.address
        let attributedText = NSAttributedString(string: text)
        assert(resultDelegateCalledDidChangeRecipients: [identitiy],
               ignoreCallsResultDelegateCalledDidChangeRecipients: false)
        let addressFound = vm.handleAddressDelimiterTyped(range: emptyRange, of: attributedText)
        XCTAssertTrue(addressFound)
        XCTAssertFalse(vm.isDirty)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleAddressDelimiterTyped_empty() {
        let text = ""
        let attributedText = NSAttributedString(string: text)
        assert(resultDelegateCalledDidChangeRecipients: nil,
               ignoreCallsResultDelegateCalledDidChangeRecipients: false)
        let addressFound = vm.handleAddressDelimiterTyped(range: emptyRange, of: attributedText)
        XCTAssertFalse(addressFound)
        XCTAssertFalse(vm.isDirty)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleAddressDelimiterTyped_randomText() {
        let text = randomText
        let attributedText = NSAttributedString(string: text)
        assert(resultDelegateCalledDidChangeRecipients: nil,
               ignoreCallsResultDelegateCalledDidChangeRecipients: false)
        let addressFound = vm.handleAddressDelimiterTyped(range: emptyRange, of: attributedText)
        XCTAssertFalse(addressFound)
        XCTAssertTrue(vm.isDirty)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - Helper

    private func assert(addRecipientValue: String? = nil,
                        ignoreCallsToAddRecipient: Bool = true,
                        didChangeAttributedText: NSAttributedString? = nil,
                        ignoreCallsDidChangeAttributedText: Bool = true,
                        resultDelegateCalledDidChangeRecipients: [Identity]? = nil,
                        ignoreCallsResultDelegateCalledDidChangeRecipients: Bool = true,
                        resultDelegateCalledDidEndEditingCalled: Bool = false,
                        ignoreCallsresultDelegateCalledDidEndEditingCalled: Bool = true,
                        resultDelegateCalledTextChanged: String? = nil,
                        ignoreResultDelegateCalledTextChanged: Bool = true
        ) {
        // DELEGATE
        let expectAddRecipientCalled = expectation(description: "expectAddRecipientCalled")
        expectAddRecipientCalled.isInverted = addRecipientValue == nil
        let expectdidChangeAttributedTextCalled = expectation(
            description: "expectdidChangeAttributedTextCalled")
        expectdidChangeAttributedTextCalled.isInverted =  didChangeAttributedText == nil

        delegate = TestRecipientTextViewModelDelegate(
            expectAddRecipientCalled: ignoreCallsToAddRecipient ? nil : expectAddRecipientCalled,
            addRecipientValue: addRecipientValue,
            expectdidChangeAttributedTextCalled: ignoreCallsDidChangeAttributedText ? nil : expectdidChangeAttributedTextCalled,
            didChangeAttributedText: didChangeAttributedText)
        vm.delegate = delegate

        // RESULT DELEGATE

        let expectResultDelegateCalledDidChangeRecipients =
            expectation(description: "expectResultDelegateCalledDidChangeRecipients")
        expectResultDelegateCalledDidChangeRecipients.isInverted =
            resultDelegateCalledDidChangeRecipients == nil

        let expectresultDelegateCalledDidEndEditingCalled =
            expectation(description: "expectresultDelegateCalledDidEndEditingCalled")
        expectresultDelegateCalledDidEndEditingCalled.isInverted = !resultDelegateCalledDidEndEditingCalled

        let expectResultDelegateCalledTextChanged =
            expectation(description: "expectResultDelegateCalledTextChanged")
        expectResultDelegateCalledTextChanged.isInverted = resultDelegateCalledTextChanged == nil

        resultDelegate =
            TestRecipientTextViewModelResultDelegate(
                expectDidChangeRecipientsCalled: ignoreCallsResultDelegateCalledDidChangeRecipients ?
                    nil : expectResultDelegateCalledDidChangeRecipients,
                didChangeRecipients: resultDelegateCalledDidChangeRecipients,
                expectDidEndEditingCalled: ignoreCallsresultDelegateCalledDidEndEditingCalled ?
                    nil : expectresultDelegateCalledDidEndEditingCalled,
                expectTextChangedCalled: ignoreResultDelegateCalledTextChanged ?
                    nil : expectResultDelegateCalledTextChanged,
                textChanged: resultDelegateCalledTextChanged)
        vm.resultDelegate = resultDelegate
    }

    /// Helper to call all(or a bunch of) public methods.
    /// Use to make sure a delegate method is not called as a side effect of methods you do not
    /// expect it to.
    private func callAll(addRecipient: Bool = true,
                      shouldInteractWithTextAttachment: Bool = true,
                      handleDidEndEditing: Bool = true,
                      handleTextChange: Bool = true,
                      isAddressDeliminator: Bool = true,
                      handleAddressDelimiterTyped: Bool = true,
                      handleSelectedAttachment: Bool = true) {
        call(addRecipient: addRecipient,
             shouldInteractWithTextAttachment: shouldInteractWithTextAttachment,
             handleDidEndEditing: handleDidEndEditing,
             handleTextChange: handleTextChange,
             isAddressDeliminator: isAddressDeliminator,
             handleAddressDelimiterTyped: handleAddressDelimiterTyped,
             handleSelectedAttachment: handleSelectedAttachment)
    }

    /// Helper to call a bunch of, or all, public methods.
    /// Use to make sure a delegate method is not called as a side effect of methods you do not
    /// expect it to.
    private func call(addRecipient: Bool = false,
                      shouldInteractWithTextAttachment: Bool = false,
                      handleDidEndEditing: Bool = false,
                      handleTextChange: Bool = false,
                      isAddressDeliminator: Bool = false,
                      handleAddressDelimiterTyped: Bool = false,
                      handleSelectedAttachment: Bool = false) {

        if addRecipient {
            vm.add(recipient: validId)
        }
        if shouldInteractWithTextAttachment {
           _ = vm.shouldInteract(WithTextAttachment: NSTextAttachment(data: nil, ofType: nil))
        }
        if handleTextChange {
            vm.handleTextChange(newText: randomText)
        }
        if isAddressDeliminator {
            _ = vm.isAddressDeliminator(str: randomText)
        }
        if handleAddressDelimiterTyped {
            _ = vm.handleAddressDelimiterTyped(range: emptyRange, of: randomAttributedText)
        }
        if handleSelectedAttachment {
            vm.handleSelectedAttachment([])
        }




    }
}

class TestRecipientTextViewModelResultDelegate: RecipientTextViewModelResultDelegate {
    //didChangeRecipients
    let expectDidChangeRecipientsCalled: XCTestExpectation?
    let didChangeRecipients: [Identity]?
    //DidEndEditing
    let expectDidEndEditingCalled: XCTestExpectation?
    //textChanged
    let expectTextChangedCalled: XCTestExpectation?
    let textChanged: String?

    init(expectDidChangeRecipientsCalled: XCTestExpectation?, didChangeRecipients: [Identity]?,
         expectDidEndEditingCalled: XCTestExpectation?,
         expectTextChangedCalled: XCTestExpectation?,textChanged: String?) {
        //didChangeRecipients
        self.expectDidChangeRecipientsCalled = expectDidChangeRecipientsCalled
        self.didChangeRecipients = didChangeRecipients
        //DidEndEditing
        self.expectDidEndEditingCalled = expectDidEndEditingCalled
        //textChanged
        self.expectTextChangedCalled = expectTextChangedCalled
        self.textChanged = textChanged
    }

    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel,
                                didChangeRecipients newRecipients: [Identity]) {
        guard let exp = expectDidChangeRecipientsCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
        XCTAssertEqual(didChangeRecipients?.count, newRecipients.count)
        guard let expIds = didChangeRecipients  else {
            XCTFail("Inconsistant!")
            return
        }
        let expAddresses = expIds.map { $0.address }
        let addresses = newRecipients.map { $0.address }
        for add in expAddresses {
            XCTAssertTrue(addresses.contains(add))
        }
    }

    func recipientTextViewModelDidEndEditing(recipientTextViewModel: RecipientTextViewModel) {
        guard let exp = expectDidEndEditingCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
    }

    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel,
                                textChanged newText: String) {
        guard let exp = expectTextChangedCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
        guard let expectedText = textChanged else {
            XCTFail("Inconsistant!")
            return
        }
        XCTAssertEqual(newText, expectedText)
    }
}

class TestRecipientTextViewModelDelegate: RecipientTextViewModelDelegate {
    //add(recipient:)
    let expectAddRecipientCalled: XCTestExpectation?
    let addRecipientValue: String?
    //didChangeAttributedText
    let expectdidChangeAttributedTextCalled: XCTestExpectation?
    let didChangeAttributedText: NSAttributedString?

    init(expectAddRecipientCalled: XCTestExpectation?,
         addRecipientValue: String?,
         expectdidChangeAttributedTextCalled: XCTestExpectation?,
         didChangeAttributedText: NSAttributedString?) {
        //add(recipient:)
        self.addRecipientValue = addRecipientValue
        self.expectAddRecipientCalled = expectAddRecipientCalled
        //didChangeAttributedText
        self.expectdidChangeAttributedTextCalled = expectdidChangeAttributedTextCalled
        self.didChangeAttributedText = didChangeAttributedText
    }

    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel,
                                didChangeAttributedText newText: NSAttributedString) {
        guard let exp = expectdidChangeAttributedTextCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
        let expectedText = didChangeAttributedText
        XCTAssertEqual(newText, expectedText)
    }

    func add(recipient: String) {
        guard let exp = expectAddRecipientCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
        XCTAssertEqual(recipient, addRecipientValue)
    }
}

/*

wip

 public func handleAddressDelimiterTyped(range: NSRange,
 of text: NSAttributedString) -> Bool {
 let valid = tryGenerateValidAddressAndUpdateStatus(range: range, of: text)
 resultDelegate?.recipientTextViewModelDidEndEditing(recipientTextViewModel: self)
 return valid
 }

 public func handleSelectedAttachment(_ attachments: [RecipientTextViewTextAttachment]) {
 for attachment in attachments {
 removeRecipientAttachment(attachment: attachment)
 }
 }
 */



