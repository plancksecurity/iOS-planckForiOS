//
//  UnifiedInboxTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 07.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS
import PEPObjCAdapterFramework

class UnifiedInboxTest: AccountDrivenTestBase {
    let unifiedInbox = UnifiedInbox()
    let expectedMessages = 2

    override func setUp() {
        super.setUp()
        let account1 = TestData().createWorkingAccount()
        account1.session.commit()
        let account2 = TestData().createWorkingAccount(number: 1)
        account2.session.commit()
        let folder1 = Folder(name: "inbox", parent: nil, account: account1, folderType: .inbox)
        folder1.session.commit()
        let folder2 = Folder(name: "inbox", parent: nil, account: account2, folderType: .inbox)
        folder2.session.commit()
        let folder3 = Folder(name: "folder", parent: nil, account: account1, folderType: .normal)
        folder3.session.commit()
        let folder4 = Folder(name: "sent", parent: nil, account: account2, folderType: .sent)
        folder4.session.commit()
        let msg1 = Message(uuid: "uuidm1", parentFolder: folder1)
        msg1.session.commit()
        let msg2 = Message(uuid: "uuidm2", parentFolder: folder2)
        msg2.session.commit()
        let msg3 = Message(uuid: "uuidm3", parentFolder: folder3)
        msg3.session.commit()
        let msg4 = Message(uuid: "uuidm4", parentFolder: folder4)
        msg4.session.commit()
    }

    func testUnifiedInboxPredicateReturnAllMessagesInInbox() {

        let mgqr = MessageQueryResults(withFolder: unifiedInbox)
        do {
            try mgqr.startMonitoring()
            let count = try mgqr.count()
            XCTAssertEqual(count, 2)
        }
        catch {
            XCTFail()
        }

    }
    
}
