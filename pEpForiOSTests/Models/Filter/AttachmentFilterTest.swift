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
        let acc = cdAccount.account()

        let id = Identity.create(address: "fake@mail.com")
        id.save()
        let f1 = Folder(name: "inbox", parent: nil, account: acc, folderType: .inbox)
        f1.account = acc
        f1.save()

        let attachment = Attachment.create(data: nil, mimeType: "type", fileName: "name")
        let message = Message(uuid: "1", parentFolder: f1)
        message.from = id
        message.to = [acc.user]
        message.imapFlags?.seen = false
        message.pEpRatingInt = 16
        message.attachments = [attachment]
        message.save()

        let message2 = Message(uuid: "2", parentFolder: f1)
        message2.from = id
        message2.to = [acc.user]
        message2.imapFlags?.seen = false
        message2.pEpRatingInt = 16
        message2.save()

        let cf = CompositeFilter<FilterBase>()
        cf.add(filter: AttachmentFilter())
        let _ = f1.updateFilter(filter: cf)

        XCTAssertEqual(f1.allCdMessagesNonThreaded().count, 1)
    }
}
