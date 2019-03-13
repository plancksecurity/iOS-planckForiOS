//
//  AttachmentFilterTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 19.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
import pEpForiOS

class AttachmentFilterTest: CoreDataDrivenTestBase {

    func testGetMessagesWithAttatchemnts() {
        let f1 = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        f1.save()
        let messages = createDecryptedMessages(in: f1, numMessages: 2)

        let attachment = Attachment.create(data: nil, mimeType: "type", fileName: "name")
        let firstMessage = messages.first!
        firstMessage.attachments = [attachment]
        firstMessage.save()

        let cf = CompositeFilter<FilterBase>()
        cf.add(filter: AttachmentFilter())
        let _ = f1.updateFilter(filter: cf)

         let numOfEncryptableMessagesWithAttchment = 1
        XCTAssertEqual(f1.allCdMessages().count, numOfEncryptableMessagesWithAttchment)
    }

    // MARK: - Undecryptable Messages

    func testFilterShouldIgnoreUndecryptable_haveNoKey() {
        assureMessagesDoNotPassFilter(with: PEP_rating_have_no_key)
    }

    func testFilterShouldIgnoreUndecryptable_canNotDecrypt() {
        assureMessagesDoNotPassFilter(with: PEP_rating_cannot_decrypt)
    }

    // MARK: - Helper

    func assureMessagesDoNotPassFilter(with pEpRating: PEP_rating) {
        let f1 = Folder(name: "inbox", parent: nil, account: account, folderType: .inbox)
        f1.save()
        let messages = createMessages(in: f1, numMessages: 2)
        let attachment = Attachment.create(data: nil, mimeType: "type", fileName: "name")
        let firstMessage = messages.first!
        firstMessage.attachments = [attachment]
        firstMessage.save()

        let _ = createMessages(in: f1,
                               numMessages: 3,
                               pEpRating: pEpRating)

        let cf = CompositeFilter<FilterBase>()
        cf.add(filter: AttachmentFilter())
        let _ = f1.updateFilter(filter: cf)

        let numOfEncryptableMessagesWithAttchment = 1
        XCTAssertEqual(f1.allCdMessages().count, numOfEncryptableMessagesWithAttchment)
    }

    private func createDecryptedMessages(in folder: Folder, numMessages: Int) -> [Message] {
        return createMessages(in: folder, numMessages: numMessages)
    }

    private func createMessages(in folder: Folder, numMessages: Int,
                                pEpRating: PEP_rating = PEP_rating_trusted) -> [Message] {
        let id = Identity.create(address: "fake@mail.com")
        id.save()

        var messages = [Message]()
        for i in 1...numMessages {
            let message = Message(uuid: UUID().uuidString, uid: i, parentFolder: folder)
            message.from = id
            message.to = [account.user]
            message.imapFlags?.seen = false
            message.pEpRatingInt = Int(pEpRating.rawValue)
            message.save()
            messages.append(message)
        }
        return messages
    }
}
