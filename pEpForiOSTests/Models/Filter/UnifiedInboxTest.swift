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

class UnifiedInboxTest: CoreDataDrivenTestBase {
    let unifiedInbox = UnifiedInbox()
    let expectedMessages = 2

    override func setUp() {
        super.setUp()
        let account1 = SecretTestData().createWorkingAccount()
        account1.save()
        let account2 = SecretTestData().createWorkingAccount(number: 1)
        account2.save()
        let folder1 = Folder(name: "inbox", parent: nil, account: account1, folderType: .inbox)
        folder1.save()
        let folder2 = Folder(name: "inbox", parent: nil, account: account2, folderType: .inbox)
        folder2.save()
        let folder3 = Folder(name: "folder", parent: nil, account: account1, folderType: .normal)
        folder3.save()
        let folder4 = Folder(name: "sent", parent: nil, account: account2, folderType: .sent)
        folder4.save()
        let msg1 = Message(uuid: "uuidm1", parentFolder: folder1)
        msg1.save()
        let msg2 = Message(uuid: "uuidm2", parentFolder: folder2)
        msg2.save()
        let msg3 = Message(uuid: "uuidm3", parentFolder: folder3)
        msg3.save()
        let msg4 = Message(uuid: "uuidm4", parentFolder: folder4)
        msg4.save()
    }

    func testUnifiedInboxPredicateRetunrAllMessagesInInbox() {

        let mgqr = MessageQueryResults(withDisplayableFolder: unifiedInbox)
        do {
            try mgqr.startMonitoring()
        }
        catch {
            XCTFail()
        }
        XCTAssertNotEqual(mgqr.count, 0)
        XCTAssertEqual(mgqr.count, 2)
    }
    
}
