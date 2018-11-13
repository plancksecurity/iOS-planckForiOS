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
        msg.to = [account.user]
        msg.cc = [account.user]
        msg.shortMessage = "shortMessage"
        msg.longMessage = "longMessage"
        msg.attachments = [Attachment(data: nil, mimeType: "mimeType",
                                      contentDisposition: .attachment)]
        msg.save()
        messageAllButBccSet = msg
    }

    override func tearDown() {
        inbox = nil
        drafts = nil
        outbox = nil
        messageAllButBccSet = nil
        testee = nil
        super.tearDown()
    }

    /// Asserts the testee for the given values. Optional arguments set to `nil` are ignored.
    private func assertTesteeForExpectedValues( composeMode: ComposeUtil.ComposeMode? = nil,
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

    /*

     /// Recipient to set as "To:".
     /// Is ignored if a originalMessage is set.
     public let prefilledTo: Identity?
     /// Original message to compute content and recipients from (e.g. a message we reply to).
     public let originalMessage: Message?

     public let composeMode: ComposeUtil.ComposeMode

     /// Whether or not the original message is in Drafts or Outbox
     var isDraftsOrOutbox: Bool {
     return isDrafts || isOutbox
     }

     /// Whether or not the original message is in Drafts folder
     var isDrafts: Bool {
     if let om = originalMessage {
     return om.parent.folderType == .drafts
     }
     return false
     }

     /// Whether or not the original message is in Outbox
     var isOutbox: Bool {
     if let om = originalMessage {
     return om.parent.folderType == .outbox
     }
     return false
     }

     var pEpProtection: Bool {
     return originalMessage?.pEpProtected ?? true
     }

     var from: Identity? {
     return ComposeUtil.initialFrom(composeMode: composeMode,
     originalMessage: originalMessage)
     }

     var toRecipients: [Identity] {
     if let om = originalMessage {
     return ComposeUtil.initialTos(composeMode: composeMode, originalMessage: om)
     } else if let presetTo = prefilledTo {
     return [presetTo]
     }
     return []
     }

     var ccRecipients: [Identity] {
     guard let om = originalMessage else {
     return []
     }
     return ComposeUtil.initialCcs(composeMode: composeMode, originalMessage: om)
     }

     var bccRecipients: [Identity] {
     guard let om = originalMessage else {
     return []
     }
     return ComposeUtil.initialBccs(composeMode: composeMode, originalMessage: om)
     }

     var subject = " "

     var bodyPlaintext = ""
     var bodyHtml: NSAttributedString?

     public var nonInlinedAttachments: [Attachment] {
     return ComposeUtil.initialAttachments(composeMode: composeMode,
     contentDisposition: .attachment,
     originalMessage: originalMessage)
     }

     public var inlinedAttachments: [Attachment] {
     return ComposeUtil.initialAttachments(composeMode: composeMode,
     contentDisposition: .inline,
     originalMessage: originalMessage)
     }

     init(withPrefilledToRecipient prefilledTo: Identity? = nil,
     orForOriginalMessage om: Message? = nil,
     composeMode: ComposeUtil.ComposeMode? = nil) {
     self.composeMode = composeMode ?? ComposeUtil.ComposeMode.normal
     self.originalMessage = om
     self.prefilledTo = om == nil ? prefilledTo : nil
     setupInitialSubject()
     setupInitialBody()
     }

     */

}
