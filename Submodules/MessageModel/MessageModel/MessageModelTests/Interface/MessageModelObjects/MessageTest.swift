//
//  MessageTest.swift
//  MessageModel
//
//  Created by Andreas Buff on 24.08.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel

class MessageTest: PersistentStoreDrivenTestBase {

    func testModifiedAttachments() {
        let numAttachmentsBefore = 2
        let message = TestUtil.createMessage(numAttachments: numAttachmentsBefore)
        guard let inbox = cdAccount.account().firstFolder(ofType: .inbox) else {
            XCTFail("No Inbox")
            return
        }
        message.parent = inbox
        message.session.commit()

        let attachmentUpdate = message.attachments[0]
        let newFileName = "newFileName"
        attachmentUpdate.fileName = newFileName

        let attachmentDelete = message.attachments[1]
        message.removeFromAttachments(attachmentDelete)

        guard let mimeType = attachmentUpdate.mimeType else {
            XCTFail()
            return
        }
        let attachmentInsert = Attachment(data: attachmentUpdate.data,
                                          mimeType: mimeType,
                                          contentDisposition: attachmentUpdate.contentDisposition)
        message.appendToAttachments(attachmentInsert)
        message.session.commit()

        guard let savedCdMessage = CdMessage.search(message: message) else {
            XCTFail("Saved message not found")
            return
        }
        let msg = MessageModelObjectUtils.getMessage(fromCdMessage: savedCdMessage)
        XCTAssertFalse(msg.attachments.contains(attachmentDelete))

        let found = msg.attachments.filter { $0 == attachmentUpdate }
        XCTAssertTrue(found.count == 1)
        guard let updatesAttachmentAfterSaving = found.first else {
            XCTFail("Count == 1 but we can not get first? Somthing is fishy here.")
            return
        }
        XCTAssertEqual(updatesAttachmentAfterSaving.fileName, newFileName)
        XCTAssertTrue(msg.attachments.contains(attachmentUpdate))

        XCTAssertTrue(msg.attachments.contains(attachmentInsert))
    }
}
