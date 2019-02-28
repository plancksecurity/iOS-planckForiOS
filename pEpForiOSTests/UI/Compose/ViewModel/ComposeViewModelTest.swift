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
    var vm: ComposeViewModel?
    var outbox: Folder? {
        return account.folder(ofType: .outbox)
    }
    var drafts: Folder? {
        return account.folder(ofType: .drafts)
    }
    var sent: Folder? {
        return account.folder(ofType: .sent)
    }

    override func setUp() {
        super.setUp()
        vm = ComposeViewModel(resultDelegate: nil,
                              composeMode: nil,
                              prefilledTo: nil,
                              originalMessage: nil)
        assureOutboxExists()
        assureDraftsExists()
        assureSentExists()
    }

    // MARK: - Test the Test Helper

    func testAssertHelperTest_doNothing_noCallback() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

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

    func testInit_stateSetupCorrectly() {
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

    // MARK: - Sections

    func testSections_setupCorrectly() {
        let testOriginalMessage = draftMessage(bccSet: false, attachmentsSet: false)
        assertSections(forVMIniitaliizedWith: testOriginalMessage,
                       expectBccWrapperSectionExists: true,
                       expectAccountSectionExists: false,
                       expectAttachmentSectionExists: false)
    }

    func testSections_unwrappedbcc() {
        let testOriginalMessage = draftMessage(bccSet: true, attachmentsSet: false)
        assertSections(forVMIniitaliizedWith: testOriginalMessage,
                       expectBccWrapperSectionExists: false,
                       expectAccountSectionExists: false,
                       expectAttachmentSectionExists: false)
    }

    func testSections_accountSelector() {
        let testOriginalMessage = draftMessage(bccSet: false, attachmentsSet: false)
        let secondAccount = SecretTestData().createWorkingAccount(number: 1)
        secondAccount.save()
        assertSections(forVMIniitaliizedWith: testOriginalMessage,
                       expectBccWrapperSectionExists: true,
                       expectAccountSectionExists: true,
                       expectAttachmentSectionExists: false)
    }

    func testSections_attachments() {
        let testOriginalMessage = draftMessage(bccSet: false, attachmentsSet: true)
        assertSections(forVMIniitaliizedWith: testOriginalMessage,
                       expectBccWrapperSectionExists: true,
                       expectAccountSectionExists: false,
                       expectAttachmentSectionExists: true)
    }

    // MARK: - DocumentAttachmentPickerResultDelegate Handling

    func testDocumentAttachmentPickerViewModel() {
        let testee = vm?.documentAttachmentPickerViewModel()
        XCTAssertNotNil(testee)
    }

    func testDidPickDocumentAttachment() {
        let attachmentSectionSection = 4
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: true,
               expectedSection: attachmentSectionSection,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: true,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let countBefore = vm?.state.nonInlinedAttachments.count ?? -1
        let att = attachment()
        vm?.documentAttachmentPickerViewModel(TestDocumentAttachmentPickerViewModel(), didPick: att)
        let countAfter = vm?.state.nonInlinedAttachments.count ?? -1
        XCTAssertEqual(countAfter, countBefore + 1)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testDocumentAttachmentPickerDone() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: true,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        vm?.documentAttachmentPickerViewModelDidCancel(TestDocumentAttachmentPickerViewModel())
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - MediaAttachmentPickerProviderViewModelResultDelegate Handling

    func testMediaAttachmentPickerProviderViewModelFactory() {
        let testee = vm?.mediaAttachmentPickerProviderViewModel()
        XCTAssertNotNil(testee)
    }

    func testDidSelectMediaAttachment_image() {
        let msg = draftMessage()
        let imageAttachment = attachment(ofType: .inline)
        msg.attachments = [imageAttachment]
        assert(originalMessage: msg,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: true,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let mediaAtt =
            MediaAttachmentPickerProviderViewModel.MediaAttachment(type: .image,
                                                                   attachment: imageAttachment)
        let countBefore = vm?.state.inlinedAttachments.count ?? -1
        vm?.mediaAttachmentPickerProviderViewModel(
            TestMediaAttachmentPickerProviderViewModel(resultDelegate: nil),
            didSelect: mediaAtt)
        let countAfter = vm?.state.inlinedAttachments.count ?? -1
        XCTAssertEqual(countAfter, countBefore + 1)
        waitForExpectations(timeout: UnitTestUtils.waitTime)

    }

    func testDidSelectMediaAttachment_video() {
        let msg = draftMessage()
        let imageAttachment = attachment(ofType: .inline)
        msg.attachments = [imageAttachment]

        let attachmentSectionSection = 4

        assert(originalMessage: msg,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: true,
               expectedSection: attachmentSectionSection,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: true,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let mediaAtt =
            MediaAttachmentPickerProviderViewModel.MediaAttachment(type: .movie,
                                                                   attachment: imageAttachment)
        let countBefore = vm?.state.nonInlinedAttachments.count ?? -1
        vm?.mediaAttachmentPickerProviderViewModel(
            TestMediaAttachmentPickerProviderViewModel(resultDelegate: nil),
            didSelect: mediaAtt)
        let countAfter = vm?.state.nonInlinedAttachments.count ?? -1
        XCTAssertEqual(countAfter, countBefore + 1)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testMediaPickerDidCancel() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: true,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
      vm?.mediaAttachmentPickerProviderViewModelDidCancel(
        TestMediaAttachmentPickerProviderViewModel(resultDelegate: nil))
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - BodyCellViewModelResultDelegate handling

    private var bodyVm: BodyCellViewModel {
        return vm?.bodyVM ?? BodyCellViewModel(resultDelegate: nil)
    }

    func testBodyVM() {
        let testee = vm?.bodyVM
        XCTAssertNotNil(testee)
    }

    func testBodyCellViewModelUserWantsToAddMedia() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: true,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        vm?.bodyCellViewModelUserWantsToAddMedia(bodyVm)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testBodyCellViewModelUserWantsToAddDocument() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: true,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        vm?.bodyCellViewModelUserWantsToAddDocument(bodyVm)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testBodyCellViewModelInlinedAttachmentsChanged_moreAttachments() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: true,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let countBefore = vm?.state.inlinedAttachments.count ?? -1
        vm?.bodyCellViewModel(bodyVm,
                              inlinedAttachmentsChanged: [attachment()])
        let countAfter = vm?.state.inlinedAttachments.count ?? -1
        XCTAssertEqual(countAfter, countBefore + 1)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testBodyCellViewModelInlinedAttachmentsChanged_lessAttachments() {
        let msg = draftMessage()
        let imageAttachment = attachment(ofType: .inline)
        msg.attachments = [imageAttachment]
        assert(originalMessage: msg,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: true,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let lessAttachments = [Attachment]()
        vm?.bodyCellViewModel(bodyVm,
                              inlinedAttachmentsChanged: lessAttachments)
        XCTAssertEqual(vm?.state.inlinedAttachments.count, lessAttachments.count)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testBodyChangedToPlaintextHtml() {
        assert(contentChangedMustBeCalled: true,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let newPlaintext = "newPlaitext"
        let newHtml = "<p>fake</p>"
        vm?.bodyCellViewModel(bodyVm,
                              bodyChangedToPlaintext: newPlaintext,
                              html: newHtml)
        XCTAssertEqual(vm?.state.bodyHtml, newHtml)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - SubjectCellViewModelResultDelegate Handling

    private var subjectCellViewModel: SubjectCellViewModel? {
        return viewmodel(ofType: SubjectCellViewModel.self) as? SubjectCellViewModel
    }

    func testSubjectCellViewModelDidChangeSubject() {
        assert(contentChangedMustBeCalled: true,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard let subjectVm = subjectCellViewModel  else {
            XCTFail()
            return
        }
        let newSubject = "testSubjectCellViewModelDidChangeSubject content"
        subjectVm.content = newSubject
        vm?.subjectCellViewModelDidChangeSubject(subjectVm)
        XCTAssertEqual(vm?.state.subject, newSubject)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - AccountCellViewModelResultDelegate handling

    private var accountCellViewModel: AccountCellViewModel? {
        return viewmodel(ofType: AccountCellViewModel.self) as? AccountCellViewModel
    }

    func testAccountCellViewModelAccountChangedTo() {
        let secondAccount = SecretTestData().createWorkingAccount(number: 1)
        secondAccount.save()
        assert(contentChangedMustBeCalled: true,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: true,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard let accountVm = accountCellViewModel else {
            XCTFail()
            return
        }
        vm?.accountCellViewModel(accountVm, accountChangedTo: secondAccount)
        XCTAssertEqual(vm?.state.from, secondAccount.user)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - RecipientCellViewModelResultDelegate Handling

    private func recipientCellViewModel(type: RecipientCellViewModel.FieldType) -> RecipientCellViewModel? {
        guard let sections = vm?.sections else {
            XCTFail()
            return nil
        }
        for section in sections {
            for row in section.rows where row is RecipientCellViewModel {
                if let row = row as? RecipientCellViewModel, row.type == type {
                    return row
                }
            }
        }
        return nil
    }

    func testRecipientCellViewModelDidChangeRecipients_to() {
        assertRecipientCellViewModelDidChangeRecipients(fieldType: .to)
    }

    func testRecipientCellViewModelDidChangeRecipients_cc() {
        assertRecipientCellViewModelDidChangeRecipients(fieldType: .cc)
    }

    func testRecipientCellViewModelDidChangeRecipients_bcc() {
        assertRecipientCellViewModelDidChangeRecipients(fieldType: .bcc)
    }

    func testRecipientCellViewModelDidEndEditing() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: true,
               validatedStateChangedMustBeCalled: true,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: true,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard let recipientVm = recipientCellViewModel(type: .to) else {
            XCTFail()
            return
        }
        vm?.recipientCellViewModelDidEndEditing(recipientVm)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testRecipientCellViewModelDidBeginEditing() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: true,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard let recipientVm = recipientCellViewModel(type: .to) else {
            XCTFail()
            return
        }
        let text = "testRecipientCellViewModelDidBeginEditing text"
        vm?.recipientCellViewModel(recipientVm, didBeginEditing: text)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testRecipientCellViewModelTextChanged() {
        assert(contentChangedMustBeCalled: true,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: true,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: true,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard let recipientVm = recipientCellViewModel(type: .to) else {
            XCTFail()
            return
        }
        let text = "testRecipientCellViewModelDidBeginEditing text"
        vm?.recipientCellViewModel(recipientVm, textChanged: text)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - Cancel Actions

    /*
    func testShowKeepInOutbox() {
        FolderType.allCases.forEach {
            assertShowKeepInOutbox(forMessageInfolderOfType: $0)
        }
    }
 */

    func testShowCancelActionsv() {
        let msg = message()
        assert(originalMessage: msg)
        guard let testee = vm?.showCancelActions else {
            XCTFail()
            return
        }
        XCTAssertFalse(testee)
    }

    func testShowCancelActions_edited() {
        let msg = message()
        assert(originalMessage: msg)
        vm?.state.toRecipients = [Identity(address: "testShow@Cancel.Actions")]
        guard let testee = vm?.showCancelActions else {
            XCTFail()
            return
        }
        XCTAssertTrue(testee)
    }

    func testHandleSaveActionTriggered() {
        assert(originalMessage: nil,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)

        let testSubject = UUID().uuidString + "testSubject"
        vm?.state.subject = testSubject

        vm?.handleSaveActionTriggered()

        guard
            let draftsFolder = drafts,
            let testeeDrafted = Message.by(uid: 0,
                                           folderName: draftsFolder.name,
                                           accountAddress: account.user.address)
            else {
                XCTFail("Message not saved to drafts")
                return
        }
        XCTAssertEqual(testeeDrafted.shortMessage, testSubject)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleSaveActionTriggered_origOutbox() {
        let testMessageId = UUID().uuidString + "testHandleSaveActionTriggered"
        let originalMessage = message(inFolderOfType: .outbox)
        originalMessage.messageID = testMessageId
        originalMessage.from = account.user

        assert(originalMessage: originalMessage,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: true)
        vm?.handleSaveActionTriggered()
        let msgWithTestMessageId = Message.by(uid: originalMessage.uid,
                                              uuid: originalMessage.uuid,
                                              folderName: originalMessage.parent.name,
                                              accountAddress: account.user.address)
        XCTAssertNil(msgWithTestMessageId,
                     "original message must be deleted, a copy is safed to drafts")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleSaveActionTriggered_origDrafts() {
        let testMessageId = UUID().uuidString + "testHandleSaveActionTriggered"
        let originalMessage = message(inFolderOfType: .drafts)
        originalMessage.messageID = testMessageId
        originalMessage.from = account.user

        assert(originalMessage: originalMessage,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: true,
               didDeleteMessageMustBeCalled: true)
        vm?.handleSaveActionTriggered()
        let msgWithTestMessageId = Message.by(uid: originalMessage.uid,
                                              uuid: originalMessage.uuid,
                                              folderName: originalMessage.parent.name,
                                              accountAddress: account.user.address,
                                              includingDeleted: true)
        XCTAssertTrue(msgWithTestMessageId?.imapFlags?.deleted ?? false,
                     "The user edited draft. Technically we save a new message, thus the original" +
            " must be deleted.")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleDeleteActionTriggered_normal() {
        assert(originalMessage: nil,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        vm?.handleSaveActionTriggered()
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleDeleteActionTriggered_origOutbox() {
        let testMessageId = UUID().uuidString + "testHandleDeleteActionTriggered_origOutbox"
        let originalMessage = message(inFolderOfType: .outbox)
        originalMessage.messageID = testMessageId
        originalMessage.from = account.user

        assert(originalMessage: originalMessage,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: true)
        vm?.handleSaveActionTriggered()
        let msgWithTestMessageId = Message.by(uid: originalMessage.uid,
                                              uuid: originalMessage.uuid,
                                              folderName: originalMessage.parent.name,
                                              accountAddress: account.user.address)
        XCTAssertNil(msgWithTestMessageId,
                     "original message must be deleted, a copy is safed to drafts")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - Suggestions

    func testSuggestViewModel() {
        let testee = vm?.suggestViewModel()
        XCTAssertNotNil(testee)
        XCTAssertTrue(testee?.resultDelegate === vm)
    }

    // showSuggestions and hideSuggestions are tested altering recipients

    func testShowSuggestionsScrollFocus_nonEmpty() {
        let expectedSuggestionsVisibility = true
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               expectedIsValidated: nil,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               suggestionsScrollFocusChangedMustBeCalled: true,
               expectedNewSuggestionsScrollFocusIsVisible: expectedSuggestionsVisibility,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let _ = vm?.suggestViewModel(SuggestViewModel(),
                                     didToggleVisibilityTo: expectedSuggestionsVisibility)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testShowSuggestionsScrollFocus_empty() {
        let expectedSuggestionsVisibility = false
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               expectedIsValidated: nil,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               suggestionsScrollFocusChangedMustBeCalled: true,
               expectedNewSuggestionsScrollFocusIsVisible: expectedSuggestionsVisibility,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let _ = vm?.suggestViewModel(SuggestViewModel(),
                                     didToggleVisibilityTo: expectedSuggestionsVisibility)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

// MARK: - ComposeViewModelStateDelegate Handling

    func testComposeViewModelStateDidChangeValidationStateTo() {
        let expectedIsValid = true
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: true,
               expectedIsValidated: expectedIsValid,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard let state = vm?.state else {
            XCTFail()
            return
        }
        vm?.composeViewModelState(state, didChangeValidationStateTo: expectedIsValid)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testComposeViewModelDidChangePEPRatingTo() {
        let expectedRating = PEPRatingReliable
        vm?.state.pEpProtection = true
        let expectedProtection = vm?.state.pEpProtection ?? false
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: true,
               expectedRating: expectedRating,
               expectedProtectionEnabled: expectedProtection,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard let state = vm?.state else {
            XCTFail()
            return
        }
        vm?.composeViewModelState(state, didChangePEPRatingTo: expectedRating)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - Delegate Setter Side Effect

    func testDelegateSetter() {
        let expectedRating = PEPRatingUndefined
        let expectedProtection = true
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: true,
               expectedRating: expectedRating,
               expectedProtectionEnabled: expectedProtection,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        vm?.delegate = testDelegate
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - isAttachmentSection

    func testIsAttachmentSection() {
        let msgWithAttachment = draftMessage(attachmentsSet: true)
        assert(originalMessage: msgWithAttachment)
        guard
            let lastSection = vm?.sections.last,
            let numSections = vm?.sections.count else {
                XCTFail()
                return
        }
        let numRows = lastSection.rows.count
        let idxPath = IndexPath(row: numRows - 1, section: numSections - 1)
        XCTAssertTrue(vm?.isAttachmentSection(indexPath: idxPath) ?? false,
                      "Last row in last section must be attachment")
    }

    // MARK: - handleRemovedRow

    func testHandleRemovedRow_removeAttachment() {
        let msgWithAttachments = draftMessage(attachmentsSet: true)
        msgWithAttachments.attachments.append(attachment(ofType: .attachment))
        msgWithAttachments.save()
        assert(originalMessage: msgWithAttachments)
        vm?.state.nonInlinedAttachments = msgWithAttachments.attachments
        guard
            let lastSectionBefore = vm?.sections.last,
            let numSectionsBefore = vm?.sections.count,
            let numNonIlinedAttachmentsBefore = vm?.state.nonInlinedAttachments.count
            else {
                XCTFail()
                return
        }
        let numRowsBefore  = lastSectionBefore.rows.count
        let attachmentIdxPath = IndexPath(row: numRowsBefore - 1,
                                          section: numSectionsBefore - 1)
        // Test
        vm?.handleRemovedRow(at: attachmentIdxPath)
        guard
            let lastSectionAfter = vm?.sections.last,
            let numSectionsAfter = vm?.sections.count,
            let numNonIlinedAttachmentsAfter = vm?.state.nonInlinedAttachments.count
            else {
                XCTFail()
                return
        }
        let numRowsAfter = lastSectionAfter.rows.count
        XCTAssertEqual(numNonIlinedAttachmentsAfter, numNonIlinedAttachmentsBefore - 1)
        XCTAssertEqual(numSectionsAfter, numSectionsBefore)
        XCTAssertEqual(numRowsAfter, numRowsBefore - 1, "Attachment is removed")
    }

    // MARK: - handleUserClickedSendButton

    func testHandleUserClickedSendButton() {
        assert()
        let toRecipient = Identity(address: "testHandleUserClickedSend@Butt.on")
        vm?.state.toRecipients = [toRecipient]
        vm?.state.from = account.user
        let outMsgsBefore = Folder.by(account: account, folderType: .outbox)?
            .allMessagesNonThreaded()
            .count ?? -1
        vm?.handleUserClickedSendButton()
        let outMsgsAfter = Folder.by(account: account, folderType: .outbox)?
            .allMessagesNonThreaded()
            .count ?? -1
        XCTAssertEqual(outMsgsAfter, outMsgsBefore + 1)
        XCTAssertGreaterThan(outMsgsAfter, 0)
    }

    func testHandleUserClickedSendButton_origDraft() {
        let testMessageId = UUID().uuidString + #function
        let originalMessage = draftMessage()
        originalMessage.messageID = testMessageId
        originalMessage.from = account.user
        originalMessage.save()
        XCTAssertNotNil(Message.by(uid: originalMessage.uid,
                                   uuid: originalMessage.uuid,
                                   folderName: originalMessage.parent.name,
                                   accountAddress: account.user.address))
        assert(originalMessage: originalMessage)
        let toRecipient = Identity(address: "testHandleUserClickedSend@Butt.on")
        vm?.state.toRecipients = [toRecipient]
        vm?.state.from = account.user
        vm?.handleUserClickedSendButton()
        guard
            let originalDraftedMessageDeleted =
            Message.by(uid: originalMessage.uid,
                       uuid: originalMessage.uuid,
                       folderName: originalMessage.parent.name,
                       accountAddress: account.user.address,
                       includingDeleted: true)?.imapFlags?.deleted
            else {
                XCTFail()
                return
        }
        XCTAssertTrue(originalDraftedMessageDeleted,
                      "original drafted message must be flagged deleted")
    }

    func testHandleUserClickedSendButton_origOutbox() {
        let testMessageId = UUID().uuidString + #function
        let originalMessage = message(inFolderOfType: .outbox)
        originalMessage.messageID = testMessageId
        originalMessage.from = account.user
        originalMessage.save()
        XCTAssertNotNil(Message.by(uid: originalMessage.uid,
                                   uuid: originalMessage.uuid,
                                   folderName: originalMessage.parent.name,
                                   accountAddress: account.user.address))
        assert(originalMessage: originalMessage)
        let toRecipient = Identity(address: "testHandleUserClickedSend@Butt.on")
        vm?.state.toRecipients = [toRecipient]
        vm?.state.from = account.user
        vm?.handleUserClickedSendButton()
        if let _ = Message.by(uid: originalMessage.uid,
                              uuid: originalMessage.uuid,
                              folderName: originalMessage.parent.name,
                              accountAddress: account.user.address) {
            XCTFail("original message must not exist (must be deleted)")
            return
        }
    }

    // MARK: - handleUserChangedProtectionStatus

    func testHandleUserChangedProtectionStatus_change() {
        let expectedRating = PEPRatingUndefined
        let expectedProtection = false
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: true,
               expectedRating: expectedRating,
               expectedProtectionEnabled: expectedProtection,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        vm?.handleUserChangedProtectionStatus(to: false)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleUserChangedProtectionStatus_noChange() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        vm?.handleUserChangedProtectionStatus(to: true)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - handleUserSelectedRow

    func testHandleUserSelectedRow_ccWrapped_wrapperCellSelected() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: true,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard
            let wrapperVM = viewmodel(ofType: WrappedBccViewModel.self),
            let idxPath = indexPath(for: wrapperVM) else {
                XCTFail("No VM")
                return
        }
        vm?.handleUserSelectedRow(at: idxPath)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleUserSelectedRow_ccWrapped_recipientCellSelected() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let idxPathToRecipients = IndexPath(row: 0, section: 0)
        vm?.handleUserSelectedRow(at: idxPathToRecipients)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleUserSelectedRow_ccUnwrapped_recipientCellSelected() {
        let originalMessage = draftMessage()
        assert(originalMessage: originalMessage,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let idxPathToRecipients = IndexPath(row: 0, section: 0)
        vm?.handleUserSelectedRow(at: idxPathToRecipients)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - viewModel(for:)

    func testViewModelForIndexPath() {
        assert(contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard
            let wrapperVM = viewmodel(ofType: WrappedBccViewModel.self),
            let idxPath = indexPath(for: wrapperVM) else {
                XCTFail("No VM")
                return
        }
        guard let testee = vm?.viewModel(for: idxPath) else {
            XCTFail()
            return
        }
        XCTAssertTrue(testee === wrapperVM)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testViewModelForIndexPath_notAlwaysWrapper() {
        assert()
        guard let wrapperVM = viewmodel(ofType: WrappedBccViewModel.self) else {
                XCTFail("No VM")
                return
        }
        let toRecipientsIdxPath = IndexPath(row: 0, section: 0)
        guard let testee = vm?.viewModel(for: toRecipientsIdxPath) else {
            XCTFail()
            return
        }
        XCTAssertFalse(testee === wrapperVM)
    }

    // MARK: - beforePickerFocus

    func testBeforePickerFocus() {
        assert()
        guard let bodyVm = vm?.bodyVM else {
            XCTFail()
            return
        }
        let beforeFocus = indexPath(for: bodyVm)
        let testee = vm?.beforePickerFocus()
        XCTAssertEqual(testee, beforeFocus)
        let toRecipientsIndPath = IndexPath(row: 0, section: 0)
        XCTAssertNotEqual(testee, toRecipientsIndPath)
    }

    // MARK: - initialFocus

    func testInitialFocus_emptyTo() {
        let originalMessage = draftMessage()
        originalMessage.to = []
        originalMessage.save()
        assert(originalMessage: originalMessage,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard let testee = vm?.initialFocus() else {
            XCTFail()
            return
        }
        let toRecipientsIndPath = IndexPath(row: 0, section: 0)
        XCTAssertEqual(testee, toRecipientsIndPath)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testInitialFocus_toSet() {
        let originalMessage = draftMessage()
        originalMessage.to = [account.user]
        originalMessage.save()
        assert(originalMessage: originalMessage,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard
            let testee = vm?.initialFocus(),
            let bodyVM = vm?.bodyVM,
            let bodyIndexPath = indexPath(for: bodyVM)
            else {
                XCTFail()
                return
        }
        let toRecipientsIndexPath = IndexPath(row: 0, section: 0)
        XCTAssertEqual(testee, bodyIndexPath)
        XCTAssertNotEqual(testee, toRecipientsIndexPath)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - Helper

    private func indexPath(for cellViewModel: CellViewModel) -> IndexPath? {
        guard let vm = vm else {
            XCTFail("No VM")
            return nil
        }
        for s in 0..<vm.sections.count {
            let section = vm.sections[s]
            for r in 0..<section.rows.count {
                let row = section.rows[r]
                if row === cellViewModel {
                    return IndexPath(row: r, section: s)
                }
            }
        }
        return nil
    }

    private func assureOutboxExists() {
        if outbox == nil {
            let createe = Folder(name: "outbox", parent: nil, account: account, folderType: .outbox)
            createe.save()
        }
        XCTAssertNotNil(outbox)
    }

    private func assureDraftsExists() {
        if drafts == nil {
            let createe = Folder(name: "drafts",
                                 parent: nil,
                                 account: account,
                                 folderType: .drafts)
            createe.save()
        }
        XCTAssertNotNil(drafts)
    }

    private func assureSentExists() {
        if sent == nil {
            let createe = Folder(name: "sent",
                                 parent: nil,
                                 account: account,
                                 folderType: .sent)
            createe.save()
        }
        XCTAssertNotNil(sent)
    }

    private func assertShowKeepInOutbox(forMessageInfolderOfType type: FolderType) {
        let msg = message(inFolderOfType: type)
        assert(originalMessage: msg,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: false,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: false,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        let testee = vm?.showKeepInOutbox
        XCTAssertEqual(testee, type == .outbox)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    private func assertRecipientCellViewModelDidChangeRecipients(
        fieldType type: RecipientCellViewModel.FieldType) {
        let secondAccount = SecretTestData().createWorkingAccount(number: 1)
        secondAccount.save()
        let om = draftMessage(bccSet: true, attachmentsSet: false)
        assert(originalMessage: om,
               contentChangedMustBeCalled: false,
               focusSwitchedMustBeCalled: false,
               validatedStateChangedMustBeCalled: true,
               modelChangedMustBeCalled: false,
               sectionChangedMustBeCalled: false,
               colorBatchNeedsUpdateMustBeCalled: true,
               hideSuggestionsMustBeCalled: false,
               showSuggestionsMustBeCalled: false,
               showMediaAttachmentPickerMustBeCalled: false,
               hideMediaAttachmentPickerMustBeCalled: false,
               showDocumentAttachmentPickerMustBeCalled: false,
               documentAttachmentPickerDonePickerCalled: false,
               didComposeNewMailMustBeCalled: false,
               didModifyMessageMustBeCalled: false,
               didDeleteMessageMustBeCalled: false)
        guard let recipientVm = recipientCellViewModel(type: type) else {
            XCTFail()
            return
        }

        let beforeCount: Int
        switch type {
        case .to:
            beforeCount = vm?.state.toRecipients.count ?? -2
        case .cc:
            beforeCount = vm?.state.ccRecipients.count ?? -2
        case .bcc:
            beforeCount = vm?.state.bccRecipients.count ?? -2
        }

        let newRecipients = [account.user, secondAccount.user]
        vm?.recipientCellViewModel(recipientVm, didChangeRecipients: newRecipients)

        let afterCount: Int
        switch type {
        case .to:
            afterCount = vm?.state.toRecipients.count ?? -2
        case .cc:
            afterCount = vm?.state.ccRecipients.count ?? -2
        case .bcc:
            afterCount = vm?.state.bccRecipients.count ?? -2
        }
        XCTAssertNotEqual(afterCount, beforeCount)
        XCTAssertEqual(afterCount, newRecipients.count)
        waitForExpectations(timeout: UnitTestUtils.asyncWaitTime) // Async calls involved (get pEp color)
    }

    private func viewmodel(ofType vmType: AnyClass) -> CellViewModel? {
        guard let sections = vm?.sections else {
            XCTFail()
            return nil
        }
        for section in sections {
            guard let vm = section.rows.first else {
                continue
            }
            if type(of: vm) == vmType {
                return  section.rows.first
            }
        }
        return nil
    }

    private func draftMessage(bccSet: Bool = false, attachmentsSet: Bool = false) -> Message {
        return message(inFolderOfType: .drafts, bccSet: bccSet, attachmentsSet: attachmentsSet)
    }

    private func message(inFolderOfType parentType: FolderType = .inbox,
                         bccSet: Bool = false,
                         attachmentsSet: Bool = false) -> Message {
        let folder = Folder(name: "\(parentType)",
            parent: parentType == .inbox ? nil : account.folder(ofType: .inbox),
            account: account,
            folderType: parentType)
        folder.save()
        let createe = Message(uuid: UUID().uuidString, parentFolder: folder)
        if bccSet {
            createe.bcc = [account.user]
        }
        if attachmentsSet {
            let att = attachment()
            createe.attachments = [att]
        }
        createe.save()
        return createe
    }

    private func attachment(
        ofType type: Attachment.ContentDispositionType = .attachment ) -> Attachment {
        let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg"
        guard
            let imageData = TestUtil.loadData(fileName: imageFileName),
            let image = UIImage(data: imageData) else {
            XCTFail()
            return Attachment(data: nil, mimeType: "meh", contentDisposition: .attachment)
        }
        let createe: Attachment
        if type == .inline {
            createe = Attachment(data: imageData,
                       mimeType: "image/jpg",
                       size: imageData.count,
                       image: image,
                       contentDisposition: type)
        } else {
            createe = Attachment(data: imageData,
                                 mimeType: "video/quicktime",
                                 size: imageData.count,
                                 contentDisposition: type)
        }
        createe.fileName = UUID().uuidString
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
                        expectedRating: PEPRating? = nil,
                        expectedProtectionEnabled: Bool? = nil,
                        hideSuggestionsMustBeCalled: Bool? = nil,
                        showSuggestionsMustBeCalled: Bool? = nil,
                        expectedShowSuggestionsIndexPath: IndexPath? = nil,
                        suggestionsScrollFocusChangedMustBeCalled: Bool? = nil,
                        expectedNewSuggestionsScrollFocusIsVisible: Bool? = nil,
                        showMediaAttachmentPickerMustBeCalled: Bool? = nil,
                        hideMediaAttachmentPickerMustBeCalled: Bool? = nil,
                        showDocumentAttachmentPickerMustBeCalled: Bool? = nil,
                        documentAttachmentPickerDonePickerCalled: Bool? = nil,
                        didComposeNewMailMustBeCalled: Bool? = nil,/*TestResultDelegate realted params*/
                        didModifyMessageMustBeCalled: Bool? = nil,
                        didDeleteMessageMustBeCalled: Bool? = nil) {
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
            // Overfulfill is espected. When unwrapping CcBcc fields, wrapper section AND
            // recipinets section changes.
            expSectionChangedCalled?.assertForOverFulfill = false
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

        var expSuggestionsScrollFocusChangedCalled: XCTestExpectation? = nil
        if let exp = suggestionsScrollFocusChangedMustBeCalled {
            expSuggestionsScrollFocusChangedCalled =
                expectation(description: "expSuggestionsScrollFocusChangedCalled")
            expSuggestionsScrollFocusChangedCalled?.isInverted = !exp
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
                         expColorBatchNeedsUpdateCalled: nil,
                         expectedRating: expectedRating,
                         expectedProtectionEnabled: expectedProtectionEnabled,
                         expHideSuggestionsCalled: expHideSuggestionsCalled,
                         expShowSuggestionsCalled: expShowSuggestionsCalled,
                         expSuggestionsScrollFocusChangedCalled: expSuggestionsScrollFocusChangedCalled,
                         expectedScrollFocus: expectedNewSuggestionsScrollFocusIsVisible,
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
            expDidDeleteMessageCalled?.assertForOverFulfill = false
        }

        testResultDelegate =
            TestResultDelegate(expDidComposeNewMailCalled: expDidComposeNewMailCalled,
                               expDidModifyMessageCalled: expDidModifyMessageCalled,
                               expDidDeleteMessageCalled: expDidDeleteMessageCalled)
        vm = ComposeViewModel(resultDelegate: testResultDelegate,
                              composeMode: composeMode,
                              prefilledTo: prefilledTo,
                              originalMessage: originalMessage)
        vm?.delegate = testDelegate
        // Set _after_ the delegate is set because at this point we are not interested in callbacks
        // triggered by setting the delegate.
        testDelegate?.expColorBatchNeedsUpdateCalled = expColorBatchNeedsUpdateCalled
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

        var expColorBatchNeedsUpdateCalled: XCTestExpectation?
        let expectedRating: PEPRating?
        let expectedProtectionEnabled: Bool?

        let expHideSuggestionsCalled: XCTestExpectation?

        let expShowSuggestionsCalled: XCTestExpectation?
        let expectedShowSuggestionsIndexPath: IndexPath?

        let expSuggestionsScrollFocusChangedCalled: XCTestExpectation?
        let expectedScrollFocus: Bool?

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
             expectedRating: PEPRating?,
             expectedProtectionEnabled: Bool?,
             expHideSuggestionsCalled: XCTestExpectation?,
             expShowSuggestionsCalled: XCTestExpectation?,
             expSuggestionsScrollFocusChangedCalled: XCTestExpectation?,
             expectedScrollFocus: Bool?,
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
            self.expSuggestionsScrollFocusChangedCalled = expSuggestionsScrollFocusChangedCalled
            self.expectedScrollFocus = expectedScrollFocus
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

        func colorBatchNeedsUpdate(for rating: PEPRating, protectionEnabled: Bool) {
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

        func suggestions(haveScrollFocus: Bool) {
            guard let exp = expSuggestionsScrollFocusChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedScrollFocus {
                XCTAssertEqual(haveScrollFocus, expected)
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

    // MARK: - DocumentAttachmentPickerViewModel
    class TestDocumentAttachmentPickerViewModel: DocumentAttachmentPickerViewModel {} // Dummy to pass something

    // MARK: - MediaAttachmentPickerProviderViewModel
    class TestMediaAttachmentPickerProviderViewModel: MediaAttachmentPickerProviderViewModel {} // Dummy to pass something
}
