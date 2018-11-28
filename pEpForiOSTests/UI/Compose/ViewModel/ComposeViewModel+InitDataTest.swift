//
//  ComposeViewModel+InitDataTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 13.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class ComposeViewModel_InitDataTest: CoreDataDrivenTestBase {
    var inbox: Folder?
    var drafts: Folder?
    var outbox: Folder?
    var messageAllButBccSet: Message?
    var testee: ComposeViewModel.InitData?
    let someone = Identity(address: "someone@someone.someone")

    override func setUp() {
        super.setUp()
        // Folders
        let inbox = Folder(name: "Inbox", parent: nil, account: account, folderType: .inbox)
        inbox.save()
        self.inbox = inbox
        let drafts = Folder(name: "Drafts", parent: inbox, account: account, folderType: .drafts)
        drafts.save()
        self.drafts = drafts
        let outbox = Folder(name: "Outbox", parent: nil, account: account, folderType: .outbox)
        outbox.save()
        self.outbox = outbox
        let msg = Message(uuid: UUID().uuidString, parentFolder: inbox)
        msg.from = account.user
        msg.to = [account.user, someone]
        msg.cc = [someone]
        msg.shortMessage = "shortMessage"
        msg.longMessage = "longMessage"
        msg.longMessageFormatted = "longMessageFormatted"
        msg.attachments = [Attachment(data: Data(),
                                      mimeType: "image/jpg",
                                      contentDisposition: .attachment)]
        msg.attachments.append(Attachment(data: Data(),
                                          mimeType: "image/jpg",
                                          contentDisposition: .inline))
        msg.save()
        messageAllButBccSet = msg

        someone.save()
    }

    override func tearDown() {
        inbox = nil
        drafts = nil
        outbox = nil
        messageAllButBccSet = nil
        testee = nil
        super.tearDown()
    }

    // MARK: - prefilledTo

    func testPrefilledTo_set() {
        let mode = ComposeUtil.ComposeMode.normal
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: someone,
                                           orForOriginalMessage: nil,
                                           composeMode: mode)
        let expectedTo = [someone]
        assertTesteeForExpectedValues(composeMode: mode,
                                      isDraftsOrOutbox: false,
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: " ",
                                      bodyPlaintext: "",
                                      bodyHtml: nil,
                                      nonInlinedAttachments: [],
                                      inlinedAttachments: [])
    }

    func testPrefilledTo_notSet() {
        let mode = ComposeUtil.ComposeMode.normal
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: nil,
                                           composeMode: mode)
        let expectedTo = [Identity]()
        assertTesteeForExpectedValues(composeMode: mode,
                                      isDraftsOrOutbox: false,
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: " ",
                                      bodyPlaintext: "",
                                      bodyHtml: nil,
                                      nonInlinedAttachments: [],
                                      inlinedAttachments: [])
    }

    func testPrefilledTo_originalMessageWins() {
        let mode = ComposeUtil.ComposeMode.normal
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: messageAllButBccSet,
                                           composeMode: mode)
        let expectedTo = [Identity]()
        assertTesteeForExpectedValues(composeMode: mode,
                                      isDraftsOrOutbox: false,
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: " ",
                                      bodyPlaintext: "",
                                      bodyHtml: nil,
                                      nonInlinedAttachments: [],
                                      inlinedAttachments: [])
    }

    func testPrefilledFrom_set() {
        let mode = ComposeUtil.ComposeMode.normal
        testee = ComposeViewModel.InitData(prefilledFromSender:someone)
        let expectedFrom = someone
        assertTesteeForExpectedValues(composeMode: mode,
                                      isDraftsOrOutbox: false,
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: expectedFrom,
                                      toRecipients: nil,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: " ",
                                      bodyPlaintext: "",
                                      bodyHtml: nil,
                                      nonInlinedAttachments: [],
                                      inlinedAttachments: [])
    }
    // MARK: - originalMessage

    func testOriginalMessage_isSet() {
        let mode = ComposeUtil.ComposeMode.normal
        let originalMessage = messageAllButBccSet
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: originalMessage,
                                           composeMode: mode)
        let expectedTo = [Identity]()
        assertTesteeForExpectedValues(composeMode: mode,
                                      originalMessage: originalMessage,
                                      isDraftsOrOutbox: false,
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: " ",
                                      bodyPlaintext: "",
                                      bodyHtml: nil,
                                      nonInlinedAttachments: [],
                                      inlinedAttachments: [])
    }

    func testOriginalMessage_alsoSetWithGivenPrefilledTo() {
        let mode = ComposeUtil.ComposeMode.normal
        let originalMessage = messageAllButBccSet
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: someone,
                                           orForOriginalMessage: originalMessage,
                                           composeMode: mode)
        let expectedTo = [Identity]()
        assertTesteeForExpectedValues(composeMode: mode,
                                      originalMessage: originalMessage,
                                      isDraftsOrOutbox: false,
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: " ",
                                      bodyPlaintext: "",
                                      bodyHtml: nil,
                                      nonInlinedAttachments: [],
                                      inlinedAttachments: [])
    }

    // MARK: - composeMode

    func testComposeMode_default() {
        let mode: ComposeUtil.ComposeMode? = nil
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: nil,
                                           composeMode: mode)
        let defaultComposeMode = ComposeUtil.ComposeMode.normal
        assertTesteeForExpectedValues(composeMode: defaultComposeMode)
    }

    func testComposeMode_isSet_normal() {
        let mode = ComposeUtil.ComposeMode.normal
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: nil,
                                           composeMode: mode)
        let expectedComposeMode = mode
        assertTesteeForExpectedValues(composeMode: expectedComposeMode)
    }

    func testComposeMode_isSet_notNormal() {
        let mode = ComposeUtil.ComposeMode.replyFrom
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: nil,
                                           composeMode: mode)
        let expectedComposeMode = mode
        assertTesteeForExpectedValues(composeMode: expectedComposeMode)
    }

    func testComposeMode_fromInbox_normal() {
        let mode = ComposeUtil.ComposeMode.normal
        guard let originalMessage = messageAllButBccSet else {
            XCTFail("No message")
            return
        }
        let expectedHtmlBody: NSAttributedString? = nil
        assertComposeMode(mode,
                          originalMessage: originalMessage,
                          expectedHtmlBody: expectedHtmlBody)
    }

    func testComposeMode_fromInbox_forward() {
        let mode = ComposeUtil.ComposeMode.forward
        guard let originalMessage = messageAllButBccSet else {
            XCTFail("No message")
            return
        }
        let expectedSubject = ReplyUtil.forwardSubject(message: originalMessage)
        // Body
        guard let origBodyAttributedString =
            originalMessage.longMessageFormatted?.htmlToAttributedString(attachmentDelegate: nil)
            else {
                XCTFail("No body")
                return
        }
        let expectedHtmlBody = ReplyUtil.citedMessageText(textToCite: origBodyAttributedString,
                                                          fromMessage: originalMessage)
        assertComposeMode(mode,
                          originalMessage: originalMessage,
                          expectedSubject: expectedSubject,
                          expectedHtmlBody: expectedHtmlBody)
    }

    func testComposeMode_fromInbox_replyFrom() {
        let mode = ComposeUtil.ComposeMode.replyFrom
        guard let originalMessage = messageAllButBccSet else {
            XCTFail("No message")
            return
        }
        let expectedSubject = ReplyUtil.replySubject(message: originalMessage)
        let expectedBody = ReplyUtil.quotedMessageText(message: originalMessage,
                                                       replyAll: false)
        assertComposeMode(mode,
                          originalMessage: originalMessage,
                          expectedSubject: expectedSubject,
                          expectedPlaintextBody: expectedBody,
                          expectedHtmlBody: nil)
    }

    func testComposeMode_fromInbox_replyAll() {
        let mode = ComposeUtil.ComposeMode.replyAll
        guard let originalMessage = messageAllButBccSet else {
            XCTFail("No message")
            return
        }
        let expectedSubject = ReplyUtil.replySubject(message: originalMessage)
        let expectedBody = ReplyUtil.quotedMessageText(message: originalMessage,
                                                       replyAll: true)
        assertComposeMode(mode,
                          originalMessage: originalMessage,
                          expectedSubject: expectedSubject,
                          expectedPlaintextBody: expectedBody,
                          expectedHtmlBody: nil)
    }

    func testComposeMode_fromDrafts() {
        let mode = ComposeUtil.ComposeMode.normal
        guard
            let originalMessage = messageAllButBccSet,
            let drafts = drafts,
            let origSubject = originalMessage.shortMessage,
            let htmlBody =
            originalMessage.longMessageFormatted?.htmlToAttributedString(attachmentDelegate: nil)
            else {
                XCTFail()
                return
        }
        originalMessage.parent = drafts
        let expectedSubject = origSubject
        let expectedHtmlBody = htmlBody
        assertComposeMode(mode,
                          originalMessage: originalMessage,
                          expectedSubject: expectedSubject,
                          expectedHtmlBody: expectedHtmlBody)
    }

    func testComposeMode_fromOutbox() {
        let mode = ComposeUtil.ComposeMode.normal
        guard
            let originalMessage = messageAllButBccSet,
            let outbox = outbox,
            let origSubject = originalMessage.shortMessage,
            let htmlBody =
            originalMessage.longMessageFormatted?.htmlToAttributedString(attachmentDelegate: nil)
            else {
                XCTFail()
                return
        }
        originalMessage.parent = outbox
        let expectedSubject = origSubject
        let expectedHtmlBody = htmlBody
        assertComposeMode(mode,
                          originalMessage: originalMessage,
                          expectedSubject: expectedSubject,
                          expectedHtmlBody: expectedHtmlBody)
    }

    // MARK: - isDraftsOrOutbox isDrafts isOutbox

    func testIsDraftsOrOutbox_noOrigMessage() {
        let mode = ComposeUtil.ComposeMode.normal
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: nil,
                                           composeMode: mode)
        assertTesteeIsDraftsAndOrOutbox(originalMessage: nil)
    }

    func testIsDraftsOrOutbox_inbox() {
        guard let parent = inbox else {
            XCTFail("No folder")
            return
        }
        assertIsDraftsAndOrOutbox(forOriginalMessageWithParentFolder: parent)
    }

    func testIsDraftsOrOutbox_drafts() {
        guard let parent = drafts else {
            XCTFail("No folder")
            return
        }
        assertIsDraftsAndOrOutbox(forOriginalMessageWithParentFolder: parent)
    }

    func testIsDraftsOrOutbox_outbox() {
        guard let parent = outbox else {
            XCTFail("No folder")
            return
        }
        assertIsDraftsAndOrOutbox(forOriginalMessageWithParentFolder: parent)
    }

    // MARK: - from, toRecipients, ccRecipients, bccRecipients, subject, body, inlinedAttachments & nonInlinedAttachments
    // are already tested in compos mode tests

    // MARK: - pEpProtection

    func testPEpProtection_noOriginalMessage() {
        let mode = ComposeUtil.ComposeMode.normal
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: nil,
                                           composeMode: mode)
        let expectedProtected = true
        assertTesteeForExpectedValues(pEpProtection: expectedProtected)
    }

    func testPEpProtection_originalMessage() {
        let mode = ComposeUtil.ComposeMode.normal
        guard let om = messageAllButBccSet else {
            XCTFail("No message")
            return
        }
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: om,
                                           composeMode: mode)
        let expectedProtected = om.pEpProtected
        assertTesteeForExpectedValues(pEpProtection: expectedProtected)
    }

    // MARK: - nonInlinedAttachments

    func testNonInlinedAttachments() {
        ComposeUtil.ComposeMode.allCases.forEach {
            assertNonInlinedAttachments(forComposeMode: $0)
        }
    }

    // MARK: - inlinedAttachments

    func testInlinedAttachments() {
        ComposeUtil.ComposeMode.allCases.forEach {
            assertInlinedAttachments(forComposeMode: $0)
        }
    }

    // MARK: - Helper

    private func assertNonInlinedAttachments(forComposeMode mode: ComposeUtil.ComposeMode) {
        assertAttachments(orType: .attachment, forComposeMode: mode)
    }

    private func assertInlinedAttachments(forComposeMode mode: ComposeUtil.ComposeMode) {
        assertAttachments(orType: .inline, forComposeMode: mode)
    }

    private func assertAttachments(orType contentDisposition: Attachment.ContentDispositionType,
                                   forComposeMode mode: ComposeUtil.ComposeMode) {
        guard let om = messageAllButBccSet else {
            XCTFail("No message")
            return
        }
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: someone,
                                           orForOriginalMessage: om,
                                           composeMode: mode)
        let expectedAttachments =
            ComposeUtil.initialAttachments(composeMode: mode,
                                           contentDisposition: contentDisposition,
                                           originalMessage: om)
        let expectedInlinedAttachments =
            contentDisposition == .inline ? expectedAttachments : nil
        let expectedNonInlinedAttachments =
            contentDisposition == .attachment ? expectedAttachments : nil
        assertTesteeForExpectedValues(nonInlinedAttachments: expectedNonInlinedAttachments,
                                      inlinedAttachments: expectedInlinedAttachments)
    }

    private func assertIsDraftsAndOrOutbox(forOriginalMessageWithParentFolder folder: Folder) {
        let mode = ComposeUtil.ComposeMode.normal
        messageAllButBccSet?.parent = folder
        let originalMessage = messageAllButBccSet
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: originalMessage,
                                           composeMode: mode)
        assertTesteeIsDraftsAndOrOutbox(originalMessage: originalMessage)
    }

    private func assertTesteeIsDraftsAndOrOutbox(originalMessage: Message?) {
        var expectedIsDrafts = false
        var expectedIsOutbox = false
        var expectedIsDraftsOrOutbox = false
        if let om = originalMessage  {
            if om.parent.folderType == .drafts {
                expectedIsDrafts = true
            } else if om.parent.folderType == .outbox {
                expectedIsOutbox = true
            }
            expectedIsDraftsOrOutbox = expectedIsDrafts || expectedIsOutbox
        }
        assertTesteeForExpectedValues(isDraftsOrOutbox: expectedIsDraftsOrOutbox,
                                      isDrafts: expectedIsDrafts,
                                      isOutbox: expectedIsOutbox)
    }

    private func assertComposeMode(_ composeMode: ComposeUtil.ComposeMode,
                                   originalMessage: Message,
                                   expectedSubject: String = " ",
                                   expectedPlaintextBody: String = "",
                                   expectedHtmlBody: NSAttributedString?) {
        let mode = composeMode
        testee = ComposeViewModel.InitData(withPrefilledToRecipient: nil,
                                           orForOriginalMessage: originalMessage,
                                           composeMode: mode)
        let expectedTos = ComposeUtil.initialTos(composeMode: mode,
                                                 originalMessage: originalMessage)
        let expectedCcs = ComposeUtil.initialCcs(composeMode: mode,
                                                 originalMessage: originalMessage)
        let expectedBccs = ComposeUtil.initialBccs(composeMode: mode,
                                                   originalMessage: originalMessage)
        let expectedInlinedAttachments =
            ComposeUtil.initialAttachments(composeMode: mode,
                                           contentDisposition: .inline,
                                           originalMessage: originalMessage)
        let expectedNonInlinedAttachments =
            ComposeUtil.initialAttachments(composeMode: mode,
                                           contentDisposition: .attachment,
                                           originalMessage: originalMessage)
        assertTesteeForExpectedValues(composeMode: mode,
                                      originalMessage: originalMessage,
                                      isDraftsOrOutbox: nil,
                                      isDrafts: nil,
                                      isOutbox: nil,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTos,
                                      ccRecipients: expectedCcs,
                                      bccRecipients: expectedBccs,
                                      subject: expectedSubject,
                                      bodyPlaintext: expectedPlaintextBody,
                                      bodyHtml: expectedHtmlBody,
                                      nonInlinedAttachments: expectedNonInlinedAttachments,
                                      inlinedAttachments: expectedInlinedAttachments)
    }

    /// Asserts the testee for the given values. Optional arguments set to `nil` are ignored.
    private func assertTesteeForExpectedValues( composeMode: ComposeUtil.ComposeMode? = nil,
                                                originalMessage: Message? = nil,
                                                isDraftsOrOutbox: Bool? = nil,
                                                isDrafts: Bool? = nil,
                                                isOutbox: Bool? = nil,
                                                pEpProtection: Bool? = nil,
                                                from: Identity? = nil,
                                                toRecipients: [Identity]? = nil,
                                                ccRecipients: [Identity]? = nil,
                                                bccRecipients: [Identity]? = nil,
                                                subject: String? = nil,
                                                bodyPlaintext: String? = nil,
                                                bodyHtml: NSAttributedString? = nil,
                                                nonInlinedAttachments: [Attachment]? = nil,
                                                inlinedAttachments: [Attachment]? = nil) {
        guard let testee = testee else {
            XCTFail("No testee")
            return
        }
        if let exp = composeMode {
            XCTAssertEqual(testee.composeMode, exp)
        }
        if let exp = originalMessage {
            XCTAssertEqual(testee.originalMessage, exp)
        }
        if let exp = isDraftsOrOutbox {
            XCTAssertEqual(testee.isDraftsOrOutbox, exp)
        }
        if let exp = isDrafts {
            XCTAssertEqual(testee.isDrafts, exp)
        }
        if let exp = isOutbox {
            XCTAssertEqual(testee.isOutbox, exp)
        }
        if let exp = pEpProtection {
            XCTAssertEqual(testee.pEpProtection, exp)
        }
        if let exp = from {
            XCTAssertEqual(testee.from, exp)
        }
        if let exp = toRecipients {
            XCTAssertEqual(testee.toRecipients, exp)
            XCTAssertEqual(testee.toRecipients.count, exp.count)
            for to in testee.toRecipients {
                XCTAssertTrue(exp.contains(to))
            }
        }
        if let exp = ccRecipients {
            XCTAssertEqual(testee.ccRecipients, exp)
            XCTAssertEqual(testee.ccRecipients.count, exp.count)
            for to in testee.ccRecipients {
                XCTAssertTrue(exp.contains(to))
            }
        }
        if let exp = bccRecipients {
            XCTAssertEqual(testee.bccRecipients, exp)
            XCTAssertEqual(testee.bccRecipients.count, exp.count)
            for to in testee.bccRecipients {
                XCTAssertTrue(exp.contains(to))
            }
        }
        if let exp = subject {
            XCTAssertEqual(testee.subject, exp)
        }
        if let exp = bodyPlaintext {
            XCTAssertEqual(testee.bodyPlaintext, exp)
        }
        if let exp = bodyHtml {
            XCTAssertEqual(testee.bodyHtml, exp)
        }
        if let exp = nonInlinedAttachments {
            XCTAssertEqual(testee.nonInlinedAttachments, exp)
            XCTAssertEqual(testee.nonInlinedAttachments.count, exp.count)
            for to in testee.nonInlinedAttachments {
                XCTAssertTrue(exp.contains(to))
            }
        }
        if let exp = inlinedAttachments {
            XCTAssertEqual(testee.inlinedAttachments, exp)
            XCTAssertEqual(testee.inlinedAttachments.count, exp.count)
            for to in testee.inlinedAttachments {
                XCTAssertTrue(exp.contains(to))
            }
        }
    }
}
