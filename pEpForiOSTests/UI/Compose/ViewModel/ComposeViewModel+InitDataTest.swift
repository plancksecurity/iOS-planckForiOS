//
//  ComposeViewModel+InitDataTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 13.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel
import pEpIOSToolbox

class ComposeViewModel_InitDataTest: AccountDrivenTestBase {
    var inbox: Folder?
    var drafts: Folder?
    var outbox: Folder?
    var messageAllButBccSet: Message?
    var testee: ComposeViewModel.InitData?
    var someone: Identity!

    override func setUp() {
        super.setUp()

        someone = Identity(address: Constant.someone)

        // Folders
        let inbox = Folder(name: "Inbox", parent: nil, account: account, folderType: .inbox)
        inbox.session.commit()
        self.inbox = inbox
        let drafts = Folder(name: "Drafts", parent: nil, account: account, folderType: .drafts)
        drafts.session.commit()
        self.drafts = drafts
        let outbox = Folder(name: "Outbox", parent: nil, account: account, folderType: .outbox)
        outbox.session.commit()
        self.outbox = outbox
        let message = createMessage(inFolder: inbox,
                                    from: account.user,
                                    tos: [account.user, someone],
                                    ccs: [someone],
                                    bccs: [],
                                    engineProccesed: false,
                                    shortMessage: Constant.shortMessage,
                                    longMessage: Constant.longMessage,
                                    longMessageFormatted: Constant.longMessageFormattedHtml,
                                    dateSent: Date(),
                                    attachments: 0,
                                    uid: nil)

//        message.appendToAttachments(createTestAttachments())
        message.session.commit()
        messageAllButBccSet = message
        someone.session.commit()
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
        let expectedTo: [Identity] = [someone]
        assertTesteeForExpectedValues(composeMode: mode,
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: Constant.shortMessage,
                                      bodyPlaintext: Constant.bodyPlainText,
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
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: Constant.shortMessage,
                                      bodyPlaintext: Constant.bodyPlainText,
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
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: Constant.shortMessage,
                                      bodyPlaintext: Constant.bodyPlainText,
                                      bodyHtml: nil,
                                      nonInlinedAttachments: [],
                                      inlinedAttachments: [])
    }

    func testPrefilledFrom_set() {
        let mode = ComposeUtil.ComposeMode.normal
        testee = ComposeViewModel.InitData(prefilledFromSender:someone)
        let expectedFrom = someone
        assertTesteeForExpectedValues(composeMode: mode,
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: expectedFrom,
                                      toRecipients: nil,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: Constant.shortMessage,
                                      bodyPlaintext: Constant.bodyPlainText,
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
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: Constant.shortMessage,
                                      bodyPlaintext: Constant.bodyPlainText,
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
                                      isDrafts: false,
                                      isOutbox: false,
                                      pEpProtection: true,
                                      from: account.user,
                                      toRecipients: expectedTo,
                                      ccRecipients: [],
                                      bccRecipients: [],
                                      subject: Constant.shortMessage,
                                      bodyPlaintext: Constant.bodyPlainText,
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
        assertComposeMode(mode,
                          originalMessage: originalMessage,
                          expectedHtmlBody: nil)
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
        assertTesteeForExpectedValues(isDrafts: expectedIsDrafts,
                                      isOutbox: expectedIsOutbox)
    }

    private func assertComposeMode(_ composeMode: ComposeUtil.ComposeMode,
                                   originalMessage: Message,
                                   expectedSubject: String = Constant.shortMessage,
                                   expectedPlaintextBody: String = Constant.bodyPlainText,
                                   expectedHtmlBody: NSAttributedString? = nil) {
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
    private func assertTesteeForExpectedValues(composeMode: ComposeUtil.ComposeMode? = nil,
                                               originalMessage: Message? = nil,
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
            guard let originalBodyHtml = testee.bodyHtml else {
                XCTFail("No testee.bodyHtml")
                return
            }
            XCTAssertEqual(originalBodyHtml, exp)
        }
        if let exp = nonInlinedAttachments {
            let safeExp = Attachment.makeSafe(exp, forSession: Session.main)
            let safeTesteeNonInlinedAttachments = Attachment.makeSafe(testee.nonInlinedAttachments,
                                                                      forSession: Session.main)
            XCTAssertEqual(safeTesteeNonInlinedAttachments, safeExp)
            XCTAssertEqual(safeTesteeNonInlinedAttachments.count, safeExp.count)
            for to in testee.nonInlinedAttachments {
                let safeTo = to.safeForSession(Session.main)
                XCTAssertTrue(safeExp.contains(safeTo))
            }
        }
        if let exp = inlinedAttachments {
            let safeExp = Attachment.makeSafe(exp, forSession: Session.main)
            let safeTesteeInlinedAttachments = Attachment.makeSafe(testee.inlinedAttachments,
                                                                      forSession: Session.main)

            XCTAssertEqual(safeTesteeInlinedAttachments, safeExp)
            XCTAssertEqual(safeTesteeInlinedAttachments.count, safeExp.count)
            for to in testee.inlinedAttachments {
                let safeTo = to.safeForSession(Session.main)
                XCTAssertTrue(safeExp.contains(safeTo))
            }
        }
    }
}

// MARK: - Mock data

extension ComposeViewModel_InitDataTest {
    private struct Constant {
        static let someone = "someone@someone.someone"
        static let shortMessage = " "
        static let shortMessageReply = "Re:" + Constant.shortMessage
        static let shortMessageForward = "Fwd:" + Constant.shortMessage
        static let bodyPlainText = ""
        static let bodyHtml = ""
        static let longMessage = "longMessage"
        static let longMessageFormatted = "Test"
        static let longMessageFormattedHtml = "<html><p>Test</p></html>"
        static let longMessageFormattedAttribString = NSAttributedString(string: Constant.longMessageFormatted)
    }
    private func getStandardJpgData() -> Data {
        let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg"
        guard let imageData = MiscUtil.loadData(bundleClass: ComposeViewModel_InitDataTest.self,
                                                fileName: imageFileName) else {
            XCTFail("imageData is nil!")
            return Data()
        }
        return imageData
    }
    private func createTestAttachments(numAttachments: Int = 1,
                                 data: Data? = nil,
                                 mimeType: String = "test/mimeType",
                                 fileName: String? = nil,
                                 size: Int? = nil,
                                 url: URL? = nil,
                                 addImage: Bool = false,
                                 assetUrl: URL? = nil,
                                 contentDisposition: Attachment.ContentDispositionType = .inline)
        -> [Attachment] {
            var attachments = [Attachment]()
            let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg" //IOS-1399: move to Utils
            guard
                let imageData = MiscUtil.loadData(bundleClass: ComposeViewModel_InitDataTest.self,
                                                  fileName: imageFileName),
                let image = UIImage(data: imageData) else {
                    XCTFail("No img")
                    return []
            }

            for i in 0..<numAttachments {
                attachments.append(Attachment(data: data,
                                              mimeType: mimeType,
                                              fileName: fileName == nil ? "\(i)" : fileName,
                                              image: addImage ? image : nil,
                                              assetUrl: assetUrl,
                                              contentDisposition: contentDisposition))
            }
            return attachments
    }
    private func createMessage(inFolder folder: Folder,
                              from: Identity,
                              tos: [Identity] = [],
                              ccs: [Identity] = [],
                              bccs: [Identity] = [],
                              engineProccesed: Bool = true,
                              shortMessage: String = Constant.shortMessage,
                              longMessage: String = Constant.longMessage,
                              longMessageFormatted: String = Constant.longMessageFormatted,
                              dateSent: Date = Date(),
                              attachments: Int = 0,
                              uid: Int? = nil) -> Message {
        let msg: Message
        if let uid = uid {
            msg = Message(uuid: UUID().uuidString, uid: uid, parentFolder: folder)
        } else {
            msg = Message(uuid: UUID().uuidString, parentFolder: folder)
        }
        msg.from = from
        msg.replaceTo(with: tos)
        msg.replaceCc(with: ccs)
        msg.replaceBcc(with: bccs)
        msg.messageID = UUID().uuidString
        msg.shortMessage = shortMessage
        msg.longMessage = longMessage
        msg.longMessageFormatted = longMessageFormatted
        msg.sent = dateSent
        return msg
    }
}

