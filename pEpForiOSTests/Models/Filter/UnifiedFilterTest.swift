//
//  UnifiedFilterTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 05.09.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import MessageModel
import pEpForiOS

class UnifiedFilterTest: CoreDataDrivenTestBase {

    func testGetUnifiedInbox() {
        let acc = cdAccount.account()
        let acc2 = SecretTestData().createWorkingAccount(number: 1)
        acc2.save()

        let id = Identity.create(address: "fake@mail.com")
        id.save()
        let f1 = Folder(name: "inbox", parent: nil, account: acc, folderType: .inbox)
        f1.account = acc
        f1.save()

        let f2 = Folder(name: "inbox", parent: nil, account: acc2, folderType: .inbox)
        f2.account = acc2
        f2.save()

        let message = Message(uuid: "1", parentFolder: f1) //IOS-1274: fix test
        message.from = id
        message.to = [acc.user]
        message.imapFlags?.seen = false
        message.pEpRatingInt = 16
        message.save()

        let message2 = Message(uuid: "2", parentFolder: f2)
        message2.from = id
        message2.to = [acc2.user]
        message2.imapFlags?.seen = false
        message2.pEpRatingInt = 16
        message2.save()


        let cf = CompositeFilter<FilterBase>()
        cf.add(filter: UnifiedFilter())
        let _ = f1.updateFilter(filter: cf)

        XCTAssertEqual(f1.allCdMessagesNonThreaded().count, 2)
    }
}
