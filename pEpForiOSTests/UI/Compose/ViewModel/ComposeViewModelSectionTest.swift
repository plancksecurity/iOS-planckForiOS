//
//  ComposeViewModelSectionTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 15.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class ComposeViewModelSectionTest: AccountDrivenTestBase {
    var state: ComposeViewModel.ComposeViewModelState?

    override func setUp() {
        super.setUp()
        state = setupSimpleState()
    }

    override func tearDown() {
        state = nil
        super.tearDown()
    }

    // MARK: - recipients

    func test_recipients_bccWrapped() {
        let to = 1
        assert(forSectionType: .recipients,
               expectedRowType: RecipientCellViewModel.self,
               expectedNumRows: to)
    }

    func test_recipients_bccUnwrapped() {
        state?.setBccUnwrapped()
        let to = 1
        let cc = 1
        let bcc = 1
        assert(forSectionType: .recipients,
               expectedRowType: RecipientCellViewModel.self,
               expectedNumRows: to + cc + bcc)
    }

    // MARK: - wrapped

    func testWrapped_bccWrapped() {
        let wrappedCcBcc = 1
        assert(forSectionType: .wrapped,
               expectedRowType: WrappedBccViewModel.self,
               expectedNumRows: wrappedCcBcc)
    }

    func testWrapped_bccUnwrapped() {
        state?.setBccUnwrapped()
        let showsCcAndBccInsteadOfWrapper = 0
        assert(forSectionType: .wrapped,
               expectedRowType: WrappedBccViewModel.self,
               expectedNumRows: showsCcAndBccInsteadOfWrapper)
    }

    // MARK: - subject

    func testSubject() {
        let allwaysShown = 1
        assert(forSectionType: .subject,
               expectedRowType: SubjectCellViewModel.self,
               expectedNumRows: allwaysShown)
    }

    func testSubject_noMatterWhat() {
        state?.setBccUnwrapped()
        let allwaysShown = 1
        assert(forSectionType: .subject,
               expectedRowType: SubjectCellViewModel.self,
               expectedNumRows: allwaysShown)
    }

    // MARK: - account

    func testAccount_oneExisting() {
        assertAccountSection()
    }

    func testAccount_twoExisting() {
        let account = TestData().createWorkingAccount(number: 1)
        account.session.commit()
        assertAccountSection()
    }

    // MARK: - body

    func testbody() {
        let allwaysShown = 1
        assert(forSectionType: .body,
               expectedRowType: BodyCellViewModel.self,
               expectedNumRows: allwaysShown)
    }

    func testbody_noMatterWhat() {
        state?.setBccUnwrapped()
        let allwaysShown = 1
        assert(forSectionType: .body,
               expectedRowType: BodyCellViewModel.self,
               expectedNumRows: allwaysShown)
    }

    // MARK: - attachments

    func testAttachments_none() {
        assertAttchments(numInlinedAttachments: 0, numNonInlinedAttachments: 0)
    }

    func testAttachments_nonInllinedAttachment() {
        assertAttchments(numInlinedAttachments: 0, numNonInlinedAttachments: 1)
    }

    func testAttachments_nonInllinedAttachments() {
        assertAttchments(numInlinedAttachments: 0, numNonInlinedAttachments: 2)
    }

    func testAttachments_inllinedAttachment() {
        assertAttchments(numInlinedAttachments: 1, numNonInlinedAttachments: 0)
    }

    func testAttachments_inllinedAttachments() {
        assertAttchments(numInlinedAttachments: 2, numNonInlinedAttachments: 0)
    }

    func testAttachments_inllinedAndNonInlinedAttachments() {
        assertAttchments(numInlinedAttachments: 1, numNonInlinedAttachments: 1)
    }

    func testAttachments_inllinedAndNonInlinedAttachments_2() {
        assertAttchments(numInlinedAttachments: 2, numNonInlinedAttachments: 2)
    }

    private func assertAttchments(numInlinedAttachments: Int = 0,
                                  numNonInlinedAttachments: Int = 0) {
        guard let state = state else {
            XCTFail("No State")
            return
        }
        add(numAttachments: numNonInlinedAttachments, ofType: .attachment, to: state)
        add(numAttachments: numInlinedAttachments, ofType: .inline, to: state)

        let expectedNumAttachmentRows = numNonInlinedAttachments
        assert(forSectionType: .attachments,
               expectedRowType: AttachmentViewModel.self,
               expectedNumRows: expectedNumAttachmentRows)
    }

    private func add(numAttachments: Int,
                     ofType type: Attachment.ContentDispositionType,
                     to state: ComposeViewModel.ComposeViewModelState) {
        for i in 0..<numAttachments {
            let createe = Attachment(data: Data(),
                                     mimeType: "image/jpg",
                                     contentDisposition: type)
            createe.fileName = "fileName \(i)"
            if type == .inline {
                state.inlinedAttachments.append(createe)
            } else {
                state.nonInlinedAttachments.append(createe)
            }
        }
    }

    // MARK: - Helper

    func assertAccountSection() {
        let numexistingAccounts = Account.all().count
        let expectedAccountsRowShouldExist = numexistingAccounts == 1 ? 0 : 1
        assert(forSectionType: .account,
               expectedRowType: AccountCellViewModel.self,
               expectedNumRows: expectedAccountsRowShouldExist)
    }

    private func assert(forSectionType sectionType: ComposeViewModel.Section.SectionType,
                        expectedRowType: AnyClass,
                        expectedNumRows: Int) {
        guard let state = state else {
            XCTFail("No State")
            return
        }
        let createe = ComposeViewModel.Section(type: sectionType,
                                               for: state,
                                               cellVmDelegate: nil)
        if expectedNumRows == 0 {
            XCTAssertNil(createe)
            return
        }
        guard let testee = createe else {
            XCTFail("Section is expected non-empty (expectedNumRows != 0)")
            return
        }
        XCTAssertEqual(testee.rows.count, expectedNumRows)
        for row in testee.rows {
            XCTAssertTrue(type(of:row) == expectedRowType, "row is correct type")
        }
    }

    // MARK: - Setup

    private func setupSimpleState(toRecipients: [Identity] = [],
                                  ccRecipients: [Identity] = [],
                                  bccRecipients: [Identity] = [],
                                  isWapped: Bool = true) -> ComposeViewModel.ComposeViewModelState {
        let drafts = Folder(name: "Inbox", parent: nil, account: account, folderType: .drafts)
        drafts.session.commit()
        let msg = Message(uuid: UUID().uuidString, parentFolder: drafts)
        msg.from = account.user
        msg.replaceTo(with: toRecipients)
        msg.replaceCc(with: ccRecipients)
        msg.replaceBcc(with: bccRecipients)
        msg.shortMessage = "shortMessage"
        msg.longMessage = "longMessage"
        msg.longMessageFormatted = "longMessageFormatted"
        msg.replaceAttachments(with: [])
        msg.session.commit()
        let initData = ComposeViewModel.InitData(prefilledTo: nil, prefilledFrom: nil, originalMessage: msg, composeMode: .normal)
        let createe = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
        if !isWapped {
            createe.setBccUnwrapped()
        }
        return createe
    }
}
