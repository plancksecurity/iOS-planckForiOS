//
//  DercyptMessagesOperationTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 10.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

import CoreData

@testable import MessageModel
@testable import pEpForiOS

class DercyptMessagesOperationTest: CoreDataDrivenTestBase {
    var moc: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        moc = Record.Context.default
    }
    //IOS-815 pEpRating undefined
    func testPepratingUndefined() {
        let folder = CdFolder(context: moc)
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName
        Record.saveAndWait()

        guard
            let affectedMessage = TestUtil.loadData(fileName: "IOS-815_pep_rating_zero.txt"),
            let message = CWIMAPMessage(data: affectedMessage) else {
                XCTAssertTrue(false)
                return
        }
        message.setFolder(CWIMAPFolder(name: ImapSync.defaultImapInboxName))
        message.setUID(1)
        guard let msg = CdMessage.insertOrUpdate(  pantomimeMessage: message,
                                                   account: cdAccount,
                                                   messageUpdate: CWMessageUpdate.newComplete(),
                                                   context: moc)
            else {
                XCTFail("error parsing message")
                return
        }

        guard let cur = CdMessage.search(message: message, inAccount: cdAccount) else {
            XCTFail("No message")
            return
        }

        let notSeenByPepYet = Int16.min
        XCTAssertTrue(cur.pEpRating == notSeenByPepYet)
        let keyAttachment = 1
        XCTAssertEqual(cur.attachments?.count, keyAttachment)

        let errorContainer = ErrorContainer()
        let decryptOP = DecryptMessagesOperation(errorContainer: errorContainer)
        let expOpFinishes = expectation(description: "expOpFinishes")
        decryptOP.completionBlock = {
            XCTAssertFalse(errorContainer.hasErrors())
            expOpFinishes.fulfill()
        }
        decryptOP.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let temp = msg.message(),  let testee = CdMessage.search(message: temp) else {
            XCTFail("No message")
            return
        }

        XCTAssertTrue(testee.pEpRating != notSeenByPepYet)
    }
}
