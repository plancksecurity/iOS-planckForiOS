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
        let messages = createMessages(in: f1, numMessages: 2)
        let firstMessage = messages.first!

        let attachment = Attachment.create(data: nil, mimeType: "type", fileName: "name")
        firstMessage.attachments = [attachment]
        firstMessage.save()

        let cf = CompositeFilter<FilterBase>()
        cf.add(filter: AttachmentFilter())
        let _ = f1.updateFilter(filter: cf)

        XCTAssertEqual(f1.allCdMessagesNonThreaded().count, 1)
    }

    // MARK: - Helper

    private func createMessages(in folder: Folder, numMessages: Int,
                                pepRating: PEP_rating = PEP_rating_trusted) -> [Message] {
        let id = Identity.create(address: "fake@mail.com")
        id.save()


        var messages = [Message]()
        for i in 0..<numMessages {
            let message = Message(uuid: String(i), parentFolder: folder)
            message.from = id
            message.to = [account.user]
            message.imapFlags?.seen = false
            message.pEpRatingInt = Int(pepRating.rawValue)
            message.save()
            messages.append(message)
        }
        return messages
    }
}
