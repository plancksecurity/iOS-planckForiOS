//
//  ComposeViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 15.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel
import PEPObjCAdapterFramework
import pEpIOSToolbox

class ComposeViewModelTest: AccountDrivenTestBase {
    private var testDelegate: TestDelegate?
    var vm: ComposeViewModel?
    var outbox: Folder? {
        return account.firstFolder(ofType: .outbox)
    }
    var drafts: Folder? {
        return account.firstFolder(ofType: .drafts)
    }
    var sent: Folder? {
        return account.firstFolder(ofType: .sent)
    }

    override func setUp() {
        super.setUp()
        vm = ComposeViewModel(composeMode: nil,
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

    func testInit_stateSetupCorrectly() {
        let mode = ComposeUtil.ComposeMode.replyAll
        let vm = ComposeViewModel(composeMode: mode,
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
        let secondAccount = TestData().createWorkingAccount(number: 1)
        secondAccount.session.commit()
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
        vm?.documentAttachmentPickerViewModel(TestDocumentAttachmentPickerViewModel(session: Session()),
                                              didPick: att)
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
        vm?.documentAttachmentPickerViewModelDidCancel(TestDocumentAttachmentPickerViewModel(session: Session()))
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - DocumentAttachmentPickerViewModel
    class TestDocumentAttachmentPickerViewModel: DocumentAttachmentPickerViewModel {} // Dummy to pass something

    // MARK: - MediaAttachmentPickerProviderViewModel
    class TestMediaAttachmentPickerProviderViewModel: MediaAttachmentPickerProviderViewModel {} // Dummy to pass something

    // MARK: - MediaAttachmentPickerProviderViewModelResultDelegate Handling

    func testMediaAttachmentPickerProviderViewModelFactory() {
        let testee = vm?.mediaAttachmentPickerProviderViewModel()
        XCTAssertNotNil(testee)
    }

    func testDidSelectMediaAttachment_image() {
        let msg = draftMessage()
        let imageAttachment = attachment(ofType: .inline)
        msg.replaceAttachments(with: [imageAttachment])
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
            TestMediaAttachmentPickerProviderViewModel(resultDelegate: nil, session: Session()),
            didSelect: mediaAtt)
        let countAfter = vm?.state.inlinedAttachments.count ?? -1
        XCTAssertEqual(countAfter, countBefore + 1)
        waitForExpectations(timeout: UnitTestUtils.waitTime)

    }

    func testDidSelectMediaAttachment_video() {
        let msg = draftMessage()
        let imageAttachment = attachment(ofType: .inline)
        msg.replaceAttachments(with: [imageAttachment])

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
            TestMediaAttachmentPickerProviderViewModel(resultDelegate: nil, session: Session()),
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
        TestMediaAttachmentPickerProviderViewModel(resultDelegate: nil, session: Session()))
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - BodyCellViewModelResultDelegate handling

    private var bodyVm: BodyCellViewModel {
        return vm?.bodyVM ?? BodyCellViewModel(resultDelegate: nil,
                                               account: nil)
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
        msg.replaceAttachments(with: [imageAttachment])
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
        let newHtml = "<p>fake</p>"
        let attributedString = newHtml.htmlToAttributedString(attachmentDelegate: nil)
        vm?.bodyCellViewModel(bodyVm, bodyAttributedString: attributedString)
        XCTAssertEqual(vm?.state.bodyText, attributedString)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - SubjectCellViewModelResultDelegate Handling

    private var subjectCellViewModel: SubjectCellViewModel? {
        return viewmodel(ofType: SubjectCellViewModel.self) as? SubjectCellViewModel
    }
//
//    //!!!: crash
////    func testSubjectCellViewModelDidChangeSubject() {
////        assert(contentChangedMustBeCalled: true,
////               focusSwitchedMustBeCalled: false,
////               validatedStateChangedMustBeCalled: false,
////               modelChangedMustBeCalled: false,
////               sectionChangedMustBeCalled: false,
////               colorBatchNeedsUpdateMustBeCalled: false,
////               hideSuggestionsMustBeCalled: false,
////               showSuggestionsMustBeCalled: false,
////               showMediaAttachmentPickerMustBeCalled: false,
////               hideMediaAttachmentPickerMustBeCalled: false,
////               showDocumentAttachmentPickerMustBeCalled: false,
////               documentAttachmentPickerDonePickerCalled: false,
////               didComposeNewMailMustBeCalled: false,
////               didModifyMessageMustBeCalled: false,
////               didDeleteMessageMustBeCalled: false)
////        guard let subjectVm = subjectCellViewModel  else {
////            XCTFail()
////            return
////        }
////        let newSubject = "testSubjectCellViewModelDidChangeSubject content"
////        subjectVm.content = newSubject
////        vm?.subjectCellViewModelDidChangeSubject(subjectVm)
////        XCTAssertEqual(vm?.state.subject, newSubject)
////        waitForExpectations(timeout: UnitTestUtils.waitTime)
////    }
//
    // MARK: - AccountCellViewModelResultDelegate handling

    private var accountCellViewModel: AccountCellViewModel? {
        return viewmodel(ofType: AccountCellViewModel.self) as? AccountCellViewModel
    }

    func testAccountCellViewModelAccountChangedTo() {
        let secondAccount = TestData().createWorkingAccount(number: 1)
        secondAccount.session.commit()
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

//    func testRecipientCellViewModelDidChangeRecipients_to() {
//        assertRecipientCellViewModelDidChangeRecipients(fieldType: .to)
//    }
//
//    func testRecipientCellViewModelDidChangeRecipients_cc() {
//        assertRecipientCellViewModelDidChangeRecipients(fieldType: .cc)
//    }
//
//    func testRecipientCellViewModelDidChangeRecipients_bcc() {
//        assertRecipientCellViewModelDidChangeRecipients(fieldType: .bcc)
//    }

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

//    func testShowCancelActionsv() {
//        let msg = message()
//        assert(originalMessage: msg)
//        guard let testee = vm?.showCancelActions else {
//            XCTFail()
//            return
//        }
//        XCTAssertFalse(testee)
//    }

    func testShowCancelActions_edited() {
        let msg = message()
        assert(originalMessage: msg)
        let idet = Identity(address: "testShow@Cancel.Actions")
        idet.session.commit()
        vm?.state.toRecipients = [idet]
        guard let testee = vm?.showCancelActions else {
            XCTFail()
            return
        }
        XCTAssertTrue(testee)
    }

//    func testHandleSaveActionTriggered() {
//        assert(originalMessage: nil,
//               contentChangedMustBeCalled: false,
//               focusSwitchedMustBeCalled: false,
//               validatedStateChangedMustBeCalled: false,
//               modelChangedMustBeCalled: false,
//               sectionChangedMustBeCalled: false,
//               colorBatchNeedsUpdateMustBeCalled: false,
//               hideSuggestionsMustBeCalled: false,
//               showSuggestionsMustBeCalled: false,
//               showMediaAttachmentPickerMustBeCalled: false,
//               hideMediaAttachmentPickerMustBeCalled: false,
//               showDocumentAttachmentPickerMustBeCalled: false,
//               documentAttachmentPickerDonePickerCalled: false,
//               didComposeNewMailMustBeCalled: false,
//               didModifyMessageMustBeCalled: false,
//               didDeleteMessageMustBeCalled: false)
//
//        let testSubject = UUID().uuidString + "testSubject"
//        vm?.state.subject = testSubject
//
//        vm?.handleSaveActionTriggered()
//
//        guard
//            let draftsFolder = drafts,
//            let testeeDrafted = Message.by(uid: 0,
//                                           folderName: draftsFolder.name,
//                                           accountAddress: account.user.address)
//            else {
//                XCTFail("Message not saved to drafts")
//                return
//        }
//        XCTAssertEqual(testeeDrafted.shortMessage, testSubject)
//        waitForExpectations(timeout: UnitTestUtils.waitTime)
//    }

    //!!!: crash
//    func testHandleSaveActionTriggered_origOutbox() {
//        let testMessageId = UUID().uuidString + "testHandleSaveActionTriggered"
//        let originalMessage = message(inFolderOfType: .outbox)
//        originalMessage.messageID = testMessageId
//        originalMessage.from = account.user
//
//        assert(originalMessage: originalMessage,
//               contentChangedMustBeCalled: false,
//               focusSwitchedMustBeCalled: false,
//               validatedStateChangedMustBeCalled: false,
//               modelChangedMustBeCalled: false,
//               sectionChangedMustBeCalled: false,
//               colorBatchNeedsUpdateMustBeCalled: false,
//               hideSuggestionsMustBeCalled: false,
//               showSuggestionsMustBeCalled: false,
//               showMediaAttachmentPickerMustBeCalled: false,
//               hideMediaAttachmentPickerMustBeCalled: false,
//               showDocumentAttachmentPickerMustBeCalled: false,
//               documentAttachmentPickerDonePickerCalled: false,
//               didComposeNewMailMustBeCalled: false,
//               didModifyMessageMustBeCalled: false,
//               didDeleteMessageMustBeCalled: true)
//        vm?.handleSaveActionTriggered()
//        let msgWithTestMessageId = Message.by(uid: originalMessage.uid,
//                                              uuid: originalMessage.uuid,
//                                              folderName: originalMessage.parent.name,
//                                              accountAddress: account.user.address)
//        XCTAssertNil(msgWithTestMessageId,
//                     "original message must be deleted, a copy is safed to drafts")
//        waitForExpectations(timeout: UnitTestUtils.waitTime)
//    }

//    func testHandleSaveActionTriggered_origDrafts() {
//        let testMessageId = UUID().uuidString + "testHandleSaveActionTriggered"
//        let originalMessage = message(inFolderOfType: .drafts)
//        originalMessage.messageID = testMessageId
//        originalMessage.from = account.user
//
//        assert(originalMessage: originalMessage,
//               contentChangedMustBeCalled: false,
//               focusSwitchedMustBeCalled: false,
//               validatedStateChangedMustBeCalled: false,
//               modelChangedMustBeCalled: false,
//               sectionChangedMustBeCalled: false,
//               colorBatchNeedsUpdateMustBeCalled: false,
//               hideSuggestionsMustBeCalled: false,
//               showSuggestionsMustBeCalled: false,
//               showMediaAttachmentPickerMustBeCalled: false,
//               hideMediaAttachmentPickerMustBeCalled: false,
//               showDocumentAttachmentPickerMustBeCalled: false,
//               documentAttachmentPickerDonePickerCalled: false,
//               didComposeNewMailMustBeCalled: false,
//               didModifyMessageMustBeCalled: true,
//               didDeleteMessageMustBeCalled: true)
//        vm?.handleSaveActionTriggered()
//        let msgWithTestMessageId = Message.by(uid: originalMessage.uid,
//                                              uuid: originalMessage.uuid,
//                                              folderName: originalMessage.parent.name,
//                                              accountAddress: account.user.address,
//                                              includingDeleted: true)
//        XCTAssertTrue(msgWithTestMessageId?.imapFlags.deleted ?? false,
//                     "The user edited draft. Technically we save a new message, thus the original" +
//            " must be deleted.")
//        waitForExpectations(timeout: UnitTestUtils.waitTime)
//    }

    //!!!: crashes randomly due to the known issue (composeviewModel is running stuff in background (e.g.calculatePepRating() , maybe more) which we are not waiting for. to fix: extract calculatePepRating() to a dependency and mock it or wait for it to be called.

//    func testHandleSaveActionTriggered_normal() {
//        assert(originalMessage: nil,
//               contentChangedMustBeCalled: false,
//               focusSwitchedMustBeCalled: false,
//               validatedStateChangedMustBeCalled: false,
//               modelChangedMustBeCalled: false,
//               sectionChangedMustBeCalled: false,
//               colorBatchNeedsUpdateMustBeCalled: false,
//               hideSuggestionsMustBeCalled: false,
//               showSuggestionsMustBeCalled: false,
//               showMediaAttachmentPickerMustBeCalled: false,
//               hideMediaAttachmentPickerMustBeCalled: false,
//               showDocumentAttachmentPickerMustBeCalled: false,
//               documentAttachmentPickerDonePickerCalled: false,
//               didComposeNewMailMustBeCalled: false,
//               didModifyMessageMustBeCalled: false,
//               didDeleteMessageMustBeCalled: false)
//        vm?.handleSaveActionTriggered()
//        waitForExpectations(timeout: UnitTestUtils.waitTime)
//    }

    //!!!: crash
//    func testHandleDeleteActionTriggered_origOutbox() {
//        let testMessageId = UUID().uuidString + "testHandleDeleteActionTriggered_origOutbox"
//        let originalMessage = message(inFolderOfType: .outbox)
//        originalMessage.messageID = testMessageId
//        originalMessage.from = account.user
//
//        assert(originalMessage: originalMessage,
//               contentChangedMustBeCalled: false,
//               focusSwitchedMustBeCalled: false,
//               validatedStateChangedMustBeCalled: false,
//               modelChangedMustBeCalled: false,
//               sectionChangedMustBeCalled: false,
//               colorBatchNeedsUpdateMustBeCalled: false,
//               hideSuggestionsMustBeCalled: false,
//               showSuggestionsMustBeCalled: false,
//               showMediaAttachmentPickerMustBeCalled: false,
//               hideMediaAttachmentPickerMustBeCalled: false,
//               showDocumentAttachmentPickerMustBeCalled: false,
//               documentAttachmentPickerDonePickerCalled: false,
//               didComposeNewMailMustBeCalled: false,
//               didModifyMessageMustBeCalled: false,
//               didDeleteMessageMustBeCalled: true)
//        vm?.handleSaveActionTriggered()
//        let msgWithTestMessageId = Message.by(uid: originalMessage.uid,
//                                              uuid: originalMessage.uuid,
//                                              folderName: originalMessage.parent.name,
//                                              accountAddress: account.user.address)
//        XCTAssertNil(msgWithTestMessageId,
//                     "original message must be deleted, a copy is safed to drafts")
//        waitForExpectations(timeout: UnitTestUtils.waitTime)
//    }

    // MARK: - Suggestions

//    func testSuggestViewModel() {
//        let testee = vm?.suggestViewModel()
//        XCTAssertNotNil(testee)
//        XCTAssertTrue(testee?.resultDelegate === vm)
//    }

    // showSuggestions and hideSuggestions are tested altering recipients

    //!!!: crash
//    func testShowSuggestionsScrollFocus_nonEmpty() {
//        let expectedSuggestionsVisibility = true
//        assert(contentChangedMustBeCalled: false,
//               focusSwitchedMustBeCalled: false,
//               validatedStateChangedMustBeCalled: false,
//               expectedIsValidated: nil,
//               modelChangedMustBeCalled: false,
//               sectionChangedMustBeCalled: false,
//               colorBatchNeedsUpdateMustBeCalled: false,
//               hideSuggestionsMustBeCalled: false,
//               showSuggestionsMustBeCalled: false,
//               suggestionsScrollFocusChangedMustBeCalled: true,
//               expectedNewSuggestionsScrollFocusIsVisible: expectedSuggestionsVisibility,
//               showMediaAttachmentPickerMustBeCalled: false,
//               hideMediaAttachmentPickerMustBeCalled: false,
//               showDocumentAttachmentPickerMustBeCalled: false,
//               documentAttachmentPickerDonePickerCalled: false,
//               didComposeNewMailMustBeCalled: false,
//               didModifyMessageMustBeCalled: false,
//               didDeleteMessageMustBeCalled: false)
//        let _ = vm?.suggestViewModel(SuggestViewModel(),
//                                     didToggleVisibilityTo: expectedSuggestionsVisibility)
//        waitForExpectations(timeout: UnitTestUtils.waitTime)
//    }

//    func testShowSuggestionsScrollFocus_empty() {
//        let expectedSuggestionsVisibility = false
//        assert(contentChangedMustBeCalled: false,
//               focusSwitchedMustBeCalled: false,
//               validatedStateChangedMustBeCalled: false,
//               expectedIsValidated: nil,
//               modelChangedMustBeCalled: false,
//               sectionChangedMustBeCalled: false,
//               colorBatchNeedsUpdateMustBeCalled: false,
//               hideSuggestionsMustBeCalled: false,
//               showSuggestionsMustBeCalled: false,
//               suggestionsScrollFocusChangedMustBeCalled: true,
//               expectedNewSuggestionsScrollFocusIsVisible: expectedSuggestionsVisibility,
//               showMediaAttachmentPickerMustBeCalled: false,
//               hideMediaAttachmentPickerMustBeCalled: false,
//               showDocumentAttachmentPickerMustBeCalled: false,
//               documentAttachmentPickerDonePickerCalled: false,
//               didComposeNewMailMustBeCalled: false,
//               didModifyMessageMustBeCalled: false,
//               didDeleteMessageMustBeCalled: false)
//        let _ = vm?.suggestViewModel(SuggestViewModel(),
//                                     didToggleVisibilityTo: expectedSuggestionsVisibility)
//        waitForExpectations(timeout: UnitTestUtils.waitTime)
//    }

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
        let expectedRating = Rating.reliable
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
        let expectedRating = Rating.undefined
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

    // MARK: - Helper

    private func assertSections(forVMIniitaliizedWith originalMessage: Message,
                                expectBccWrapperSectionExists: Bool = true,
                                expectAccountSectionExists: Bool = false,
                                expectAttachmentSectionExists: Bool = false) {
        let vm = ComposeViewModel(composeMode: .normal,
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

    private func assureOutboxExists() {
        if outbox == nil {
            let createe = Folder(name: "outbox", parent: nil, account: account, folderType: .outbox)
            createe.session.commit()
        }
        XCTAssertNotNil(outbox)
    }

    private func assureDraftsExists() {
        if drafts == nil {
            let createe = Folder(name: "drafts",
                                 parent: nil,
                                 account: account,
                                 folderType: .drafts)
            createe.session.commit()
        }
        XCTAssertNotNil(drafts)
    }

    private func assureSentExists() {
        if sent == nil {
            let createe = Folder(name: "sent",
                                 parent: nil,
                                 account: account,
                                 folderType: .sent)
            createe.session.commit()
        }
        XCTAssertNotNil(sent)
    }

    private func draftMessage(bccSet: Bool = false, attachmentsSet: Bool = false) -> Message {
        return message(inFolderOfType: .drafts, bccSet: bccSet, attachmentsSet: attachmentsSet)
    }

    private func message(inFolderOfType parentType: FolderType = .inbox,
                         bccSet: Bool = false,
                         attachmentsSet: Bool = false) -> Message {
        let folder = Folder(name: "\(parentType)",
            parent: parentType == .inbox ? nil : account.firstFolder(ofType: .inbox),
            account: account,
            folderType: parentType)
        folder.session.commit()
        let createe = Message(uuid: UUID().uuidString, parentFolder: folder)
        if bccSet {
            createe.replaceBcc(with: [account.user])
        }
        if attachmentsSet {
            let att = attachment()
            createe.replaceAttachments(with: [att])
        }
        createe.session.commit()
        return createe
    }

    private func attachment(
        ofType type: Attachment.ContentDispositionType = .attachment ) -> Attachment {
        let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg"
        guard
            let imageData = MiscUtil.loadData(bundleClass: ComposeViewModelTest.self,
                                              fileName: imageFileName),
            let image = UIImage(data: imageData) else {
            XCTFail()
            return Attachment(data: nil, mimeType: "meh", contentDisposition: .attachment)
        }
        let createe: Attachment
        if type == .inline {
            createe = Attachment(data: image.jpegData(compressionQuality: 1.0), mimeType: "image/jpg", contentDisposition: type)
            createe.image = image
        } else {
            createe = Attachment(data: imageData,
                                 mimeType: "video/quicktime",
                                 contentDisposition: type)
        }
        createe.fileName = UUID().uuidString
        return createe
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
                        expectedRating: Rating? = nil,
                        expectedProtectionEnabled: Bool? = nil,
                        hideSuggestionsMustBeCalled: Bool? = nil,
                        showSuggestionsMustBeCalled: Bool? = nil,
                        showContactsMustBeCalled: Bool? = nil,
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

        var expShowContactsCalled: XCTestExpectation? = nil
        if let exp = showContactsMustBeCalled {
            expShowContactsCalled = expectation(description: "expShowContactsCalled")
            expShowContactsCalled?.isInverted = !exp
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
                         expShowContactsPickerCalled: expShowContactsCalled,
                         expSuggestionsScrollFocusChangedCalled: expSuggestionsScrollFocusChangedCalled,
                         expectedScrollFocus: expectedNewSuggestionsScrollFocusIsVisible,
                         expectedShowSuggestionsIndexPath: expectedShowSuggestionsIndexPath,
                         expShowMediaAttachmentPickerCalled: expShowMediaAttachmentPickerCalled,
                         expHideMediaAttachmentPickerCalled: expHideMediaAttachmentPickerCalled,
                         expShowDocumentAttachmentPickerCalled: expShowDocumentAttachmentPickerCalled,
                         expDocumentAttachmentPickerDonePickerCalled:
                expDocumentAttachmentPickerDonePickerCalled)

        vm = ComposeViewModel(composeMode: composeMode,
                              prefilledTo: prefilledTo,
                              originalMessage: originalMessage)
        vm?.delegate = testDelegate
        // Set _after_ the delegate is set because at this point we are not interested in callbacks
        // triggered by setting the delegate.
        testDelegate?.expColorBatchNeedsUpdateCalled = expColorBatchNeedsUpdateCalled
    }

    private class TestDelegate: ComposeViewModelDelegate {

        func showTwoButtonAlert(withTitle title: String, message: String, cancelButtonText: String, positiveButtonText: String, cancelButtonAction: @escaping () -> Void, positiveButtonAction: @escaping () -> Void) {
        }

        func dismiss() {
        }

        let expContentChangedCalled: XCTestExpectation?
        let expectedContentChangedIndexPath: IndexPath?

        let expFocusSwitchedCalled: XCTestExpectation?

        let expValidatedStateChangedCalled: XCTestExpectation?
        let expectedIsValidated: Bool?

        let expModelChangedCalled: XCTestExpectation?

        let expSectionChangedCalled: XCTestExpectation?
        let expectedSection: Int?

        var expColorBatchNeedsUpdateCalled: XCTestExpectation?
        let expectedRating: Rating?
        let expectedProtectionEnabled: Bool?

        let expHideSuggestionsCalled: XCTestExpectation?

        let expShowSuggestionsCalled: XCTestExpectation?
        let expShowContactsPickerCalled: XCTestExpectation?
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
             expectedRating: Rating?,
             expectedProtectionEnabled: Bool?,
             expHideSuggestionsCalled: XCTestExpectation?,
             expShowSuggestionsCalled: XCTestExpectation?,
             expShowContactsPickerCalled: XCTestExpectation?,
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
            self.expShowContactsPickerCalled = expShowContactsPickerCalled
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

        func colorBatchNeedsUpdate(for rating: Rating, protectionEnabled: Bool) {
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

        func showContactsPicker() {
            guard let exp = expShowContactsPickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
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
}
