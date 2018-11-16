//
//  ComposeViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 15.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class ComposeViewModelTest: CoreDataDrivenTestBase {
    private var testDelegate: TestDelegate?
    private var testResultDelegate: TestResultDelegate?
    var testee: ComposeViewModel?

    // MARK: - init

    func testInit_resultDelegateSet() {
        let resultDelegate = TestResultDelegate()
        let vm = ComposeViewModel(resultDelegate: resultDelegate,
                                  composeMode: nil,
                                  prefilledTo: nil,
                                  originalMessage: nil)
        guard let testee = vm.resultDelegate else {
            XCTFail()
            return
        }
        XCTAssertTrue(testee === resultDelegate)
    }

    func testInit_resultDelegateSet_stateSetupCorrectly() {
        let mode = ComposeUtil.ComposeMode.replyAll
        let vm = ComposeViewModel(resultDelegate: nil,
                                  composeMode: mode,
                                  prefilledTo: nil,
                                  originalMessage: nil)
        guard
            let testee = vm.state.initData,
            let testeeMode = vm.state.initData?.composeMode,
            let stateDelegate = vm.state.delegate else {
            XCTFail()
            return
        }
        XCTAssertNotNil(testee)
        XCTAssertEqual(testeeMode, mode)
        XCTAssertTrue(vm === stateDelegate)
    }

    // MARK: Sections

    func testInit_resultDelegateSet_sectionsSetupCorrectly() {
        let testOriginalMessage = draftMessage(bccSet: false, attachmentsSet: false)
        assertSections(forVMIniitaliizedWith: testOriginalMessage,
                       expectBccWrapperSectionExists: true,
                       expectAccountSectionExists: false,
                       expectAttachmentSectionExists: false)
    }

    func testInit_resultDelegateSet_sectionsSetupCorrectly_unwrappedbcc() {
        let testOriginalMessage = draftMessage(bccSet: true, attachmentsSet: false)
        assertSections(forVMIniitaliizedWith: testOriginalMessage,
                       expectBccWrapperSectionExists: false,
                       expectAccountSectionExists: false,
                       expectAttachmentSectionExists: false)
    }

    func testInit_resultDelegateSet_sectionsSetupCorrectly_accountSelector() {
        let testOriginalMessage = draftMessage(bccSet: false, attachmentsSet: false)
        let secondAccound = SecretTestData().createWorkingAccount(number: 1)
        secondAccound.save()
        assertSections(forVMIniitaliizedWith: testOriginalMessage,
                       expectBccWrapperSectionExists: true,
                       expectAccountSectionExists: true,
                       expectAttachmentSectionExists: false)
    }

    func testInit_resultDelegateSet_sectionsSetupCorrectly_attachments() {
        let testOriginalMessage = draftMessage(bccSet: false, attachmentsSet: true)
        assertSections(forVMIniitaliizedWith: testOriginalMessage,
                       expectBccWrapperSectionExists: true,
                       expectAccountSectionExists: false,
                       expectAttachmentSectionExists: false)
    }

    // MARK: - Helper

    private func draftMessage(bccSet: Bool = false, attachmentsSet: Bool = false) -> Message {
        let drafts = Folder(name: "Inbox", parent: nil, account: account, folderType: .drafts)
        drafts.save()
        let createe = Message(uuid: UUID().uuidString, parentFolder: drafts)
        if bccSet {
            createe.bcc = [account.user]
        }
        if attachmentsSet {
            createe.attachments = [Attachment(data: nil,
                                              mimeType: "test/type",
                                              contentDisposition: .attachment)]
        }
        createe.save()
        return createe
    }

    private func assertSections(forVMIniitaliizedWith originalMessage: Message,
                                expectBccWrapperSectionExists: Bool = true,
                                expectAccountSectionExists: Bool = false,
                                expectAttachmentSectionExists: Bool = false) {

        let vm = ComposeViewModel(resultDelegate: nil,
                                  composeMode: .normal,
                                  prefilledTo: nil,
                                  originalMessage: originalMessage)
        let testee = vm.sections
        let recipientSection = 1
        let bccWrapperSection = expectBccWrapperSectionExists ? 1 : 0
        let accountSelectorSection = expectAccountSectionExists ? 1 : 0
        let subjectSection = 1
        let bodySection = 1
        let attachmentSection = expectAttachmentSectionExists ? 1 : 0
        XCTAssertEqual(testee.count,  recipientSection +
            bccWrapperSection +
            accountSelectorSection +
            subjectSection +
            bodySection +
            attachmentSection)
    }

    private func assert(composeMode: ComposeUtil.ComposeMode? = nil,
                        prefilledTo: Identity? = nil,
                        originalMessage: Message? = nil,
                        contentChangedMustBeCalled: Bool? = nil,/*TestDelegate realted params*/
                        expectedContentChangedIndexPath: IndexPath? = nil,
                        focusSwitchedMustBeCalled: Bool? = nil,
                        validatedStateChangedMustBeCalled: Bool? = nil,
                        expectedIsValidated: Bool? = nil,
                        modelChangedMustBeCalled: Bool? = nil,
                        sectionChangedMustBeCalled: Bool? = nil,
                        expectedSection: Int? = nil,
                        colorBatchNeedsUpdateMustBeCalled: Bool? = nil,
                        expectedRating: PEP_rating? = nil,
                        expectedProtectionEnabled: Bool? = nil,
                        hideSuggestionsMustBeCalled: Bool? = nil,
                        showSuggestionsMustBeCalled: Bool? = nil,
                        expectedShowSuggestionsIndexPath: IndexPath? = nil,
                        showMediaAttachmentPickerMustBeCalled: Bool? = nil,
                        hideMediaAttachmentPickerMustBeCalled: Bool? = nil,
                        showDocumentAttachmentPickerMustBeCalled: Bool? = nil,
                        documentAttachmentPickerDonePickerCalled: Bool? = nil,
                        didComposeNewMailMustBeCalled: Bool? = nil,/*TestResultDelegate realted params*/
                        didModifyMessageMustBeCalled: Bool? = nil,
                        didDeleteMessageMustBeCalled: Bool?) {
        // TestDelegate
        var expContentChangedCalled: XCTestExpectation? = nil
        if let exp = contentChangedMustBeCalled {
            expContentChangedCalled =
                expectation(description: "expContentChangedCalled")
            expContentChangedCalled?.isInverted = !exp
        }

        var expFocusSwitchedCalled: XCTestExpectation? = nil
        if let exp = focusSwitchedMustBeCalled {
            expFocusSwitchedCalled =
                expectation(description: "expFocusSwitchedCalled")
            expFocusSwitchedCalled?.isInverted = !exp
        }

        var expValidatedStateChangedCalled: XCTestExpectation? = nil
        if let exp = validatedStateChangedMustBeCalled {
            expValidatedStateChangedCalled =
                expectation(description: "expValidatedStateChangedCalled")
            expValidatedStateChangedCalled?.isInverted = !exp
        }

        var expModelChangedCalled: XCTestExpectation? = nil
        if let exp = modelChangedMustBeCalled {
            expModelChangedCalled =
                expectation(description: "expModelChangedCalled")
            expModelChangedCalled?.isInverted = !exp
        }

        var expSectionChangedCalled: XCTestExpectation? = nil
        if let exp = sectionChangedMustBeCalled {
            expSectionChangedCalled =
                expectation(description: "expSectionChangedCalled")
            expSectionChangedCalled?.isInverted = !exp
        }

        var expColorBatchNeedsUpdateCalled: XCTestExpectation? = nil
        if let exp = colorBatchNeedsUpdateMustBeCalled {
            expColorBatchNeedsUpdateCalled =
                expectation(description: "expColorBatchNeedsUpdateCalled")
            expColorBatchNeedsUpdateCalled?.isInverted = !exp
        }

        var expHideSuggestionsCalled: XCTestExpectation? = nil
        if let exp = hideSuggestionsMustBeCalled {
            expHideSuggestionsCalled =
                expectation(description: "expHideSuggestionsCalled")
            expHideSuggestionsCalled?.isInverted = !exp
        }

        var expShowSuggestionsCalled: XCTestExpectation? = nil
        if let exp = showSuggestionsMustBeCalled {
            expShowSuggestionsCalled =
                expectation(description: "expShowSuggestionsCalled")
            expShowSuggestionsCalled?.isInverted = !exp
        }

        var expShowMediaAttachmentPickerCalled: XCTestExpectation? = nil
        if let exp = showMediaAttachmentPickerMustBeCalled {
            expShowMediaAttachmentPickerCalled =
                expectation(description: "expShowMediaAttachmentPickerCalled")
            expShowMediaAttachmentPickerCalled?.isInverted = !exp
        }

        var expHideMediaAttachmentPickerCalled: XCTestExpectation? = nil
        if let exp = hideMediaAttachmentPickerMustBeCalled {
            expHideMediaAttachmentPickerCalled =
                expectation(description: "expHideMediaAttachmentPickerCalled")
            expHideMediaAttachmentPickerCalled?.isInverted = !exp
        }

        var expShowDocumentAttachmentPickerCalled: XCTestExpectation? = nil
        if let exp = showDocumentAttachmentPickerMustBeCalled {
            expShowDocumentAttachmentPickerCalled =
                expectation(description: "expShowDocumentAttachmentPickerCalled")
            expShowDocumentAttachmentPickerCalled?.isInverted = !exp
        }

        var expDocumentAttachmentPickerDonePickerCalled: XCTestExpectation? = nil
        if let exp = documentAttachmentPickerDonePickerCalled {
            expDocumentAttachmentPickerDonePickerCalled =
                expectation(description: "expDocumentAttachmentPickerDonePickerCalled")
            expDocumentAttachmentPickerDonePickerCalled?.isInverted = !exp
        }

        testDelegate =
            TestDelegate(expContentChangedCalled: expContentChangedCalled,
                         expectedContentChangedIndexPath: expectedContentChangedIndexPath,
                         expFocusSwitchedCalled: expFocusSwitchedCalled,
                         expValidatedStateChangedCalled: expValidatedStateChangedCalled,
                         expectedIsValidated: expectedIsValidated,
                         expModelChangedCalled: expModelChangedCalled,
                         expSectionChangedCalled: expSectionChangedCalled,
                         expectedSection: expectedSection,
                         expColorBatchNeedsUpdateCalled: expColorBatchNeedsUpdateCalled,
                         expectedRating: expectedRating,
                         expectedProtectionEnabled: expectedProtectionEnabled,
                         expHideSuggestionsCalled: expHideSuggestionsCalled,
                         expShowSuggestionsCalled: expShowSuggestionsCalled,
                         expectedShowSuggestionsIndexPath: expectedShowSuggestionsIndexPath,
                         expShowMediaAttachmentPickerCalled: expShowMediaAttachmentPickerCalled,
                         expHideMediaAttachmentPickerCalled: expHideMediaAttachmentPickerCalled,
                         expShowDocumentAttachmentPickerCalled: expShowDocumentAttachmentPickerCalled,
                         expDocumentAttachmentPickerDonePickerCalled:
                expDocumentAttachmentPickerDonePickerCalled)

        // TestResultDelegate

        var expDidComposeNewMailCalled: XCTestExpectation? = nil
        if let exp = didComposeNewMailMustBeCalled {
            expDidComposeNewMailCalled =
                expectation(description: "expDidComposeNewMailCalled")
            expDidComposeNewMailCalled?.isInverted = !exp
        }

        var expDidModifyMessageCalled: XCTestExpectation? = nil
        if let exp = didModifyMessageMustBeCalled {
            expDidModifyMessageCalled =
                expectation(description: "expDidModifyMessageCalled")
            expDidModifyMessageCalled?.isInverted = !exp
        }

        var expDidDeleteMessageCalled: XCTestExpectation? = nil
        if let exp = didDeleteMessageMustBeCalled {
            expDidDeleteMessageCalled =
                expectation(description: "expDidDeleteMessageCalled")
            expDidDeleteMessageCalled?.isInverted = !exp
        }

        testResultDelegate =
            TestResultDelegate(expDidComposeNewMailCalled: expDidComposeNewMailCalled,
                               expDidModifyMessageCalled: expDidModifyMessageCalled,
                               expDidDeleteMessageCalled: expDidDeleteMessageCalled)
        testee = ComposeViewModel(resultDelegate: testResultDelegate,
                                  composeMode: composeMode,
                                  prefilledTo: prefilledTo,
                                  originalMessage: originalMessage)
    }

    private class TestResultDelegate: ComposeViewModelResultDelegate {
        let expDidComposeNewMailCalled: XCTestExpectation?
        let expDidModifyMessageCalled: XCTestExpectation?
        let expDidDeleteMessageCalled: XCTestExpectation?

        init(expDidComposeNewMailCalled: XCTestExpectation? = nil,
             expDidModifyMessageCalled: XCTestExpectation? = nil,
             expDidDeleteMessageCalled: XCTestExpectation? = nil) {
            self.expDidComposeNewMailCalled = expDidComposeNewMailCalled
            self.expDidModifyMessageCalled = expDidModifyMessageCalled
            self.expDidDeleteMessageCalled = expDidDeleteMessageCalled

        }

        func composeViewModelDidComposeNewMail() {
            guard let exp = expDidComposeNewMailCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func composeViewModelDidModifyMessage() {
            guard let exp = expDidModifyMessageCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func composeViewModelDidDeleteMessage() {
            guard let exp = expDidDeleteMessageCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }
    }

    private class TestDelegate:  ComposeViewModelDelegate {
        let expContentChangedCalled: XCTestExpectation?
        let expectedContentChangedIndexPath: IndexPath?

        let expFocusSwitchedCalled: XCTestExpectation?

        let expValidatedStateChangedCalled: XCTestExpectation?
        let expectedIsValidated: Bool?

        let expModelChangedCalled: XCTestExpectation?

        let expSectionChangedCalled: XCTestExpectation?
        let expectedSection: Int?

        let expColorBatchNeedsUpdateCalled: XCTestExpectation?
        let expectedRating: PEP_rating?
        let expectedProtectionEnabled: Bool?

        let expHideSuggestionsCalled: XCTestExpectation?

        let expShowSuggestionsCalled: XCTestExpectation?
        let expectedShowSuggestionsIndexPath: IndexPath?

        let expShowMediaAttachmentPickerCalled: XCTestExpectation?

        let expHideMediaAttachmentPickerCalled: XCTestExpectation?

        let expShowDocumentAttachmentPickerCalled: XCTestExpectation?

        let expDocumentAttachmentPickerDonePickerCalled: XCTestExpectation?

        init(expContentChangedCalled: XCTestExpectation?,
             expectedContentChangedIndexPath: IndexPath?,
             expFocusSwitchedCalled: XCTestExpectation?,
             expValidatedStateChangedCalled: XCTestExpectation?,
             expectedIsValidated: Bool?,
             expModelChangedCalled: XCTestExpectation?,
             expSectionChangedCalled: XCTestExpectation?,
             expectedSection: Int?,
             expColorBatchNeedsUpdateCalled: XCTestExpectation?,
             expectedRating: PEP_rating?,
             expectedProtectionEnabled: Bool?,
             expHideSuggestionsCalled: XCTestExpectation?,
             expShowSuggestionsCalled: XCTestExpectation?,
             expectedShowSuggestionsIndexPath: IndexPath?,
             expShowMediaAttachmentPickerCalled: XCTestExpectation?,
             expHideMediaAttachmentPickerCalled: XCTestExpectation?,
             expShowDocumentAttachmentPickerCalled: XCTestExpectation?,
             expDocumentAttachmentPickerDonePickerCalled: XCTestExpectation?) {
            self.expContentChangedCalled = expContentChangedCalled
            self.expectedContentChangedIndexPath = expectedContentChangedIndexPath
            self.expFocusSwitchedCalled = expFocusSwitchedCalled
            self.expValidatedStateChangedCalled = expValidatedStateChangedCalled
            self.expectedIsValidated = expectedIsValidated
            self.expModelChangedCalled = expModelChangedCalled
            self.expSectionChangedCalled = expSectionChangedCalled
            self.expectedSection = expectedSection
            self.expColorBatchNeedsUpdateCalled =  expColorBatchNeedsUpdateCalled
            self.expectedRating = expectedRating
            self.expectedProtectionEnabled = expectedProtectionEnabled
            self.expHideSuggestionsCalled = expHideSuggestionsCalled
            self.expShowSuggestionsCalled = expShowSuggestionsCalled
            self.expectedShowSuggestionsIndexPath = expectedShowSuggestionsIndexPath
            self.expShowMediaAttachmentPickerCalled = expShowMediaAttachmentPickerCalled
            self.expHideMediaAttachmentPickerCalled = expHideMediaAttachmentPickerCalled
            self.expShowDocumentAttachmentPickerCalled = expShowDocumentAttachmentPickerCalled
            self.expDocumentAttachmentPickerDonePickerCalled =
            expDocumentAttachmentPickerDonePickerCalled
        }

        func contentChanged(inRowAt indexPath: IndexPath) {
            guard let exp = expContentChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedContentChangedIndexPath {
                XCTAssertEqual(indexPath, expected)
            }
        }

        func focusSwitched() {
            guard let exp = expFocusSwitchedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func validatedStateChanged(to isValidated: Bool) {
            guard let exp = expValidatedStateChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedIsValidated {
                XCTAssertEqual(isValidated, expected)
            }
        }

        func modelChanged() {
            guard let exp = expModelChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func sectionChanged(section: Int) {
            guard let exp = expSectionChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedSection {
                XCTAssertEqual(section, expected)
            }
        }

        func colorBatchNeedsUpdate(for rating: PEP_rating, protectionEnabled: Bool) {
            guard let exp = expColorBatchNeedsUpdateCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedRating {
                XCTAssertEqual(rating, expected)
            }
            if let expectedProtection = expectedProtectionEnabled {
                XCTAssertEqual(protectionEnabled, expectedProtection)
            }
        }

        func hideSuggestions() {
            guard let exp = expHideSuggestionsCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func showSuggestions(forRowAt indexPath: IndexPath) {
            guard let exp = expShowSuggestionsCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedShowSuggestionsIndexPath {
                XCTAssertEqual(indexPath, expected)
            }
        }

        func showMediaAttachmentPicker() {
            guard let exp = expShowMediaAttachmentPickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func hideMediaAttachmentPicker() {
            guard let exp = expHideMediaAttachmentPickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func showDocumentAttachmentPicker() {
            guard let exp = expShowDocumentAttachmentPickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func documentAttachmentPickerDone() {
            guard let exp = expDocumentAttachmentPickerDonePickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }
    }
}




/*
 weak var resultDelegate: ComposeViewModelResultDelegate?
 weak var delegate: ComposeViewModelDelegate? {
 didSet {
 delegate?.colorBatchNeedsUpdate(for: state.rating,
 protectionEnabled: state.pEpProtection)
 }
 }
 public private(set) var sections = [ComposeViewModel.Section]()
 public private(set) var state: ComposeViewModelState


 init(resultDelegate: ComposeViewModelResultDelegate? = nil,
 composeMode: ComposeUtil.ComposeMode? = nil,
 prefilledTo: Identity? = nil,
 originalMessage: Message? = nil) {
 self.resultDelegate = resultDelegate
 let initData = InitData(withPrefilledToRecipient: prefilledTo,
 orForOriginalMessage: originalMessage,
 composeMode: composeMode)
 self.state = ComposeViewModelState(initData: initData)
 self.state.delegate = self
 setup()
 }

 public func viewModel(for indexPath: IndexPath) -> CellViewModel {
 return sections[indexPath.section].rows[indexPath.row]
 }

 public func initialFocus() -> IndexPath {
 if state.initData?.toRecipients.isEmpty ?? false {
 let to = IndexPath(row: 0, section: 0)
 return to
 } else {
 return indexPathBodyVm
 }
 }

 public func beforePickerFocus() -> IndexPath {
 return indexPathBodyVm
 }

 public func handleUserSelectedRow(at indexPath: IndexPath) {
 let section = sections[indexPath.section]
 if section.type == .wrapped {
 state.setBccUnwrapped()
 unwrapRecipientSection()
 }
 }

 public func handleUserChangedProtectionStatus(to protected: Bool) {
 state.pEpProtection = protected
 }

 public func handleUserClickedSendButton() {
 guard let msg = ComposeUtil.messageToSend(withDataFrom: state) else {
 Log.error(component: #function, errorString: "No message for sending")
 return
 }
 msg.save()
 guard let data = state.initData else {
 Log.shared.errorAndCrash(component: #function, errorString: "No data")
 return
 }
 if data.isDraftsOrOutbox {
 // From user perspective, we have edited a drafted message and will send it.
 // Technically we are creating and sending a new message (msg), thus we have to
 // delete the original, previously drafted one.
 deleteOriginalMessage()
 }
 resultDelegate?.composeViewModelDidComposeNewMail()
 }

 public func isAttachmentSection(indexPath: IndexPath) -> Bool {
 return sections[indexPath.section].type == .attachments
 }

 public func handleRemovedRow(at indexPath: IndexPath) {
 guard let removeeVM = viewModel(for: indexPath) as? AttachmentViewModel else {
 Log.shared.errorAndCrash(component: #function,
 errorString: "Only attachmnets can be removed by the user")
 return
 }
 removeNonInlinedAttachment(removeeVM.attachment)
 }

 // MARK: - ComposeViewModelStateDelegate

 extension ComposeViewModel: ComposeViewModelStateDelegate {

 func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
 didChangeValidationStateTo isValid: Bool) {
 let userSeemsTyping = existsDirtyCell()
 delegate?.validatedStateChanged(to: isValid && !userSeemsTyping)
 }

 func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
 didChangePEPRatingTo newRating: PEP_rating) {
 delegate?.colorBatchNeedsUpdate(for: newRating, protectionEnabled: state.pEpProtection)
 }

 func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
 didChangeProtection newValue: Bool) {
 delegate?.colorBatchNeedsUpdate(for: state.rating, protectionEnabled: newValue)
 }
 }

 // MARK: - CellViewModels

 extension ComposeViewModel {
 class Section {
 enum SectionType: CaseIterable {
 case recipients, wrapped, account, subject, body, attachments
 }
 let type: SectionType
 fileprivate(set) public var rows = [CellViewModel]()

 init?(type: SectionType, for state: ComposeViewModelState?, cellVmDelegate: ComposeViewModel) {
 self.type = type
 setupViewModels(cellVmDelegate: cellVmDelegate, for: state)
 if rows.count == 0 {
 // We want to show non-empty sections only
 return nil
 }
 }

 private func setupViewModels(cellVmDelegate: ComposeViewModel,
 for state: ComposeViewModelState?) {
 rows = [CellViewModel]()
 let isWrapped = state?.bccWrapped ?? false
 let hasCcOrBcc = (state?.ccRecipients.count ?? 0 > 0) ||
 (state?.bccRecipients.count ?? 0 > 0)
 switch type {
 case .recipients:
 rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate,
 type: .to,
 recipients: state?.toRecipients ?? []))
 if !isWrapped || hasCcOrBcc {
 rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate,
 type: .cc,
 recipients: state?.ccRecipients ?? []))
 rows.append(RecipientCellViewModel(resultDelegate: cellVmDelegate,
 type: .bcc,
 recipients: state?.bccRecipients ?? []))
 }
 case .wrapped:
 if isWrapped && !hasCcOrBcc {
 rows.append(WrappedBccViewModel())
 }
 case .account:
 if Account.all().count == 1 {
 // Accountpicker only for multi account setup
 break
 }
 var fromAccount: Account? = nil
 if let fromIdentity = state?.from {
 fromAccount = Account.by(address: fromIdentity.address)
 }
 let rowModel = AccountCellViewModel(resultDelegate: cellVmDelegate,
 initialAccount: fromAccount)
 rows.append(rowModel)
 case .subject:
 let rowModel = SubjectCellViewModel(resultDelegate: cellVmDelegate)
 if let subject = state?.subject {
 rowModel.content = subject
 }
 rows.append(rowModel)
 case .body:
 rows.append(BodyCellViewModel(resultDelegate: cellVmDelegate,
 initialPlaintext: state?.initData?.bodyPlaintext,
 initialAttributedText: state?.initData?.bodyHtml,
 inlinedAttachments: state?.initData?.inlinedAttachments))
 case .attachments:
 for att in state?.nonInlinedAttachments ?? [] {
 rows.append(AttachmentViewModel(attachment: att))
 }
 }
 }
 }

 private func resetSections() {
 var newSections = [ComposeViewModel.Section]()
 for type in ComposeViewModel.Section.SectionType.allCases {
 if let section = ComposeViewModel.Section(type: type,
 for: state,
 cellVmDelegate: self) {
 newSections.append(section)
 }
 }
 self.sections = newSections
 delegate?.modelChanged()
 }

 private func unwrapRecipientSection() {
 let maybeWrappedIdx = 1
 if sections[maybeWrappedIdx].type == .wrapped {
 let wrappedSection = sections[maybeWrappedIdx]
 wrappedSection.rows.removeAll()
 delegate?.sectionChanged(section: maybeWrappedIdx)
 }
 // Add Cc and Bcc VMs

 let recipientsSection = section(for: .recipients)
 recipientsSection?.rows.append(RecipientCellViewModel(resultDelegate: self,
 type: .cc,
 recipients: []))
 recipientsSection?.rows.append(RecipientCellViewModel(resultDelegate: self,
 type: .bcc,
 recipients: []))
 let idxRecipients = 0
 delegate?.sectionChanged(section: idxRecipients)
 }

 private func index(ofSectionWithType type: ComposeViewModel.Section.SectionType) -> Int? {
 for i in 0..<sections.count {
 if sections[i].type == type {
 return i
 }
 }
 return nil
 }

 private func section(
 `for` type: ComposeViewModel.Section.SectionType) -> ComposeViewModel.Section? {
 for section in sections {
 if section.type == type {
 return section
 }
 }
 return nil
 }

 private func indexPath(for cellViewModel: CellViewModel) -> IndexPath? {
 for s in 0..<sections.count {
 let section = sections[s]
 for r in 0..<section.rows.count {
 let row = section.rows[r]
 if row === cellViewModel {
 return IndexPath(row: r, section: s)
 }
 }
 }
 return nil
 }
 }

 // MARK: - Attachments

 extension ComposeViewModel {
 private func removeNonInlinedAttachment(_ removee: Attachment) {
 guard let section = section(for: .attachments) else {
 Log.shared.errorAndCrash(component: #function,
 errorString: "Only attachmnets can be removed by the user")
 return
 }
 // Remove from section
 var newAttachmentVMs = [AttachmentViewModel]()
 for vm in section.rows {
 guard let aVM = vm as? AttachmentViewModel else {
 Log.shared.errorAndCrash(component: #function, errorString: "Error casting")
 return
 }
 if aVM.attachment != removee {
 newAttachmentVMs.append(aVM)
 }
 }
 section.rows = newAttachmentVMs
 // Remove from state
 var newNonInlinedAttachments = [Attachment]()
 for att in state.nonInlinedAttachments {
 if att != removee {
 newNonInlinedAttachments.append(att)
 }
 }
 state.nonInlinedAttachments = newNonInlinedAttachments
 }

 private func addNonInlinedAttachment(_ att: Attachment) {
 // Add to state
 state.nonInlinedAttachments.append(att)
 // add section
 if let existing = section(for: .attachments) {
 existing.rows.append(AttachmentViewModel(attachment: att))
 } else {
 guard let new = Section(type: .attachments, for: state, cellVmDelegate: self) else {
 Log.shared.errorAndCrash(component: #function, errorString: "Invalid state")
 return
 }
 sections.append(new)
 }
 if let attachmenttSection = index(ofSectionWithType: .attachments) {
 delegate?.sectionChanged(section: attachmenttSection)
 }
 }
 }

 // MARK: - Suggestions

 extension ComposeViewModel {
 func suggestViewModel() -> SuggestViewModel {
 let createe = SuggestViewModel(resultDelegate: self)
 suggestionsVM = createe
 return createe
 }
 }

 extension ComposeViewModel: SuggestViewModelResultDelegate {
 func suggestViewModelDidSelectContact(identity: Identity) {
 guard
 let idxPath = lastRowWithSuggestions,
 let recipientVM = sections[idxPath.section].rows[idxPath.row] as? RecipientCellViewModel
 else {
 Log.shared.errorAndCrash(component: #function, errorString: "No row VM")
 return
 }
 recipientVM.add(recipient: identity)
 }
 }

 // MARK: - DocumentAttachmentPickerViewModel[ResultDelegate]

 extension ComposeViewModel {
 func documentAttachmentPickerViewModel() -> DocumentAttachmentPickerViewModel {
 return DocumentAttachmentPickerViewModel(resultDelegate: self)
 }
 }

 extension ComposeViewModel: DocumentAttachmentPickerViewModelResultDelegate {
 func documentAttachmentPickerViewModel(_ vm: DocumentAttachmentPickerViewModel,
 didPick attachment: Attachment) {
 addNonInlinedAttachment(attachment)
 delegate?.documentAttachmentPickerDone()
 }

 func documentAttachmentPickerViewModelDidCancel(_ vm: DocumentAttachmentPickerViewModel) {
 delegate?.documentAttachmentPickerDone()
 }
 }

 // MARK: - MediaAttachmentPickerProviderViewModel[ResultDelegate]

 extension ComposeViewModel {
 func mediaAttachmentPickerProviderViewModel() -> MediaAttachmentPickerProviderViewModel {
 return MediaAttachmentPickerProviderViewModel(resultDelegate: self)
 }

 func mediaAttachmentPickerProviderViewModelDidCancel(
 _ vm: MediaAttachmentPickerProviderViewModel) {
 delegate?.hideMediaAttachmentPicker()
 }
 }

 extension ComposeViewModel: MediaAttachmentPickerProviderViewModelResultDelegate {

 func mediaAttachmentPickerProviderViewModel(
 _ vm: MediaAttachmentPickerProviderViewModel,
 didSelect mediaAttachment: MediaAttachmentPickerProviderViewModel.MediaAttachment) {
 if mediaAttachment.type == .image {
 guard let bodyViewModel = bodyVM else {
 Log.shared.errorAndCrash(component: #function,
 errorString: "No bodyVM. Maybe valid as picking is async.")
 return
 }
 bodyViewModel.inline(attachment: mediaAttachment.attachment)
 } else {
 addNonInlinedAttachment(mediaAttachment.attachment)
 delegate?.hideMediaAttachmentPicker()
 }
 }
 }

 // MARK: - Cancel Actions

 extension ComposeViewModel {

 public var showKeepInOutbox: Bool {
 return state.initData?.isOutbox ?? false
 }

 public var showCancelActions: Bool {
 return existsDirtyCell() || state.edited
 }

 public var deleteActionTitle: String {
 guard let data = state.initData else {
 Log.shared.errorAndCrash(component: #function, errorString: "No data")
 return ""
 }
 let title: String
 if data.isDrafts {
 title = NSLocalizedString("Discharge changes", comment:
 "ComposeTableView: button to decide to discharge changes made on a drafted mail.")
 } else if data.isOutbox {
 title = NSLocalizedString("Delete", comment:
 "ComposeTableView: button to decide to delete a message from Outbox after " +
 "making changes.")
 } else {
 title = NSLocalizedString("Delete", comment: "compose email delete")
 }
 return title
 }

 public var saveActionTitle: String {
 guard let data = state.initData else {
 Log.shared.errorAndCrash(component: #function, errorString: "No data")
 return ""
 }
 let title: String
 if data.isDrafts {
 title = NSLocalizedString("Save changes", comment:
 "ComposeTableView: button to decide to save changes made on a drafted mail.")
 } else {
 title = NSLocalizedString("Save Draft", comment: "compose email save")
 }
 return title
 }

 public var keepInOutboxActionTitle: String {
 return NSLocalizedString("Keep in Outbox", comment:
 "ComposeTableView: button to decide to Discharge changes made on a mail in outbox.")
 }

 public var cancelActionTitle: String {
 return NSLocalizedString("Cancel", comment: "compose email cancel")
 }

 public func handleDeleteActionTriggered() {
 guard let data = state.initData else {
 Log.shared.errorAndCrash(component: #function, errorString: "No data")
 return
 }
 if data.isOutbox {
 data.originalMessage?.delete()
 resultDelegate?.composeViewModelDidDeleteMessage()
 }
 }

 public func handleSaveActionTriggered() {
 guard let data = state.initData else {
 Log.shared.errorAndCrash(component: #function, errorString: "No data")
 return
 }
 if data.isDraftsOrOutbox {
 // We are in drafts folder and, from user perespective, are editing a drafted mail.
 // Technically we have to create a new one and delete the original message, as the
 // mail is already synced with the IMAP server and thus we must not modify it.
 deleteOriginalMessage()
 if data.isOutbox {
 // Message will be saved (moved from user perspective) to drafts, but we are in
 // outbox folder.
 resultDelegate?.composeViewModelDidDeleteMessage()
 }
 }

 guard let msg = ComposeUtil.messageToSend(withDataFrom: state) else {
 Log.shared.errorAndCrash(component: #function, errorString: "No message")
 return
 }
 let acc = msg.parent.account
 if let f = Folder.by(account:acc, folderType: .drafts) {
 msg.parent = f
 msg.imapFlags?.draft = true
 msg.sent = Date()
 msg.save()
 }
 if data.isDrafts {
 // We save a modified version of a drafted message. The UI might want to updtate
 // its model.
 resultDelegate?.composeViewModelDidModifyMessage()
 }
 }
 }

 // MARK: - HandshakeViewModel

 extension ComposeViewModel {
 // There is no view model for HandshakeViewController yet, thus we are setting up the VC itself
 // as a workaround to avoid letting the VC know MessageModel
 func setup(handshakeViewController: HandshakeViewController) {
 handshakeViewController.message = ComposeUtil.messageToSend(withDataFrom: state)
 }
 }

 // MARK: - Cell-ViewModel Delegates

 // MARK: RecipientCellViewModelResultDelegate

 extension ComposeViewModel: RecipientCellViewModelResultDelegate {
 func recipientCellViewModel(_ vm: RecipientCellViewModel,
 didChangeRecipients newRecipients: [Identity]) {
 switch vm.type {
 case .to:
 state.toRecipients = newRecipients
 case .cc:
 state.ccRecipients = newRecipients
 case .bcc:
 state.bccRecipients = newRecipients
 }
 }

 func recipientCellViewModel(_ vm: RecipientCellViewModel, didBeginEditing text: String) {
 guard let idxPath = indexPath(for: vm) else {
 Log.shared.errorAndCrash(component: #function,
 errorString: "We got called by a non-existing VM?")
 return
 }
 lastRowWithSuggestions = idxPath
 delegate?.showSuggestions(forRowAt: idxPath)
 suggestionsVM?.updateSuggestion(searchString: text)
 }

 func recipientCellViewModelDidEndEditing(_ vm: RecipientCellViewModel) {
 state.validate()
 delegate?.focusSwitched()
 delegate?.hideSuggestions()
 }

 func recipientCellViewModel(_ vm: RecipientCellViewModel, textChanged newText: String) {
 guard let idxPath = indexPath(for: vm) else {
 Log.shared.errorAndCrash(component: #function,
 errorString: "We got called by a non-existing VM?")
 return
 }
 lastRowWithSuggestions = idxPath

 delegate?.contentChanged(inRowAt: idxPath)
 delegate?.showSuggestions(forRowAt: idxPath)
 suggestionsVM?.updateSuggestion(searchString: newText)
 state.validate()
 }
 }

 // MARK: AccountCellViewModelResultDelegate

 extension ComposeViewModel: AccountCellViewModelResultDelegate {
 func accountCellViewModel(_ vm: AccountCellViewModel, accountChangedTo account: Account) {
 guard let idxPath = indexPath(for: vm) else {
 Log.shared.errorAndCrash(component: #function,
 errorString: "We got called by a non-existing VM?")
 return
 }
 state.from = account.user
 delegate?.contentChanged(inRowAt: idxPath)
 }
 }

 // MARK: SubjectCellViewModelResultDelegate

 extension ComposeViewModel: SubjectCellViewModelResultDelegate {

 func subjectCellViewModelDidChangeSubject(_ vm: SubjectCellViewModel) {
 guard let idxPath = indexPath(for: vm) else {
 Log.shared.errorAndCrash(component: #function,
 errorString: "We got called by a non-existing VM?")
 return
 }
 state.subject = vm.content ?? ""
 delegate?.contentChanged(inRowAt: idxPath)
 }
 }

 // MARK: BodyCellViewModelResultDelegate

 extension ComposeViewModel: BodyCellViewModelResultDelegate {

 var bodyVM: BodyCellViewModel? {
 for section in sections where section.type == .body {
 return section.rows.first as? BodyCellViewModel
 }
 return nil
 }

 func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel) {
 delegate?.showMediaAttachmentPicker()
 }

 func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel) {
 delegate?.showDocumentAttachmentPicker()
 }

 func bodyCellViewModel(_ vm: BodyCellViewModel,
 inlinedAttachmentsChanged inlinedAttachments: [Attachment]) {
 state.inlinedAttachments = inlinedAttachments
 delegate?.hideMediaAttachmentPicker()
 }

 func bodyCellViewModel(_ vm: BodyCellViewModel,
 bodyChangedToPlaintext plain: String,
 html: String) {
 state.bodyHtml = html
 state.bodyPlaintext = plain
 guard let idxPath = indexPath(for: vm) else {
 Log.shared.errorAndCrash(component: #function,
 errorString: "We got called by a non-existing VM?")
 return
 }
 delegate?.contentChanged(inRowAt: idxPath)
 }
 }
 */
