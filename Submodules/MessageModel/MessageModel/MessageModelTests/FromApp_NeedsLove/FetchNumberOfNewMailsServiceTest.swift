///  FetchNumberOfNewMailsServiceTest.swift
///  pEpForiOSTests
///
///  Created by Dirk Zimmermann on 16.11.18.
///  Copyright © 2018 p≡p Security S.A. All rights reserved.
///

import XCTest

import CoreData
import PEPObjCAdapterFramework

@testable import MessageModel

class FetchNumberOfNewMailsServiceTest: PersistentStoreDrivenTestBase {
    var errorContainer: ErrorContainerProtocol!
    var queue: OperationQueue!

    override func setUp() {
        super.setUp()
        errorContainer = ErrorPropagator()
        queue = OperationQueue()
    }

    // MARK: - No Mails

    func testUnreadMail_normalOnly_none() {
        assertNewMailsService(numNewNormalMessages: 0, numNewAutoconsumableMessages: 0)
    }

    // MARK: - Autocomsumable Mails Only

    func testUnreadMail_autoconsumableOnly_one() {
        assertNewMailsService(numNewNormalMessages: 0, numNewAutoconsumableMessages: 1)
    }

    func testUnreadMail_autoconsumableOnly_two() {
        assertNewMailsService(numNewNormalMessages: 0, numNewAutoconsumableMessages: 2)
    }

    func testUnreadMail_autoconsumableOnly_many() {
        assertNewMailsService(numNewNormalMessages: 0, numNewAutoconsumableMessages: 5)
    }
}

// MARK: - HELPERS

extension FetchNumberOfNewMailsServiceTest {

    func assertNewMailsService(numNewNormalMessages: Int, numNewAutoconsumableMessages: Int) {
        loginIMAP(imapConnection: imapConnection, errorContainer: errorContainer, queue: queue)
        fetchFoldersIMAP(imapConnection: imapConnection, queue: queue)

        guard let numNewMailsOrig = fetchNumberOfNewMails(errorContainer: errorContainer,
                                                          context: moc)
            else {
                XCTFail()
                return
        }

        guard let cdInbox = CdFolder.by(folderType: .inbox, account: cdAccount, context: moc) else {
            XCTFail()
            return
        }

        let partnerId = CdIdentity(context: moc)
        partnerId.address = "somepartner@example.com"
        partnerId.userID = "ID_somepartner@example.com"
        partnerId.addressBookID = nil
        partnerId.userName = "USER_somepartner@example.com"

        var newMailsExpectedToBeCounted = [CdMessage]()
        var newMailsNotExpectedToBeCounted = [CdMessage]()

        // Create new normal mails
        for _ in 0..<numNewNormalMessages {
            let newNormalMail = TestUtil.createCdMessage(cdFolder: cdInbox, moc: moc)
            newNormalMail.uuid = UUID().uuidString
            newNormalMail.uid = 0
            newNormalMail.addToTo(partnerId)
            newNormalMail.shortMessage = "Are you ok?"
            newNormalMail.longMessage = "Hi there!"
            newMailsExpectedToBeCounted.append(newNormalMail)
        }

        // Create new autoconsumable mails
        for _ in 0..<numNewAutoconsumableMessages {
            let newAutoConsumableMail = TestUtil.createCdMessage(cdFolder: cdInbox, moc: moc)
            newAutoConsumableMail.uuid = UUID().uuidString
            newAutoConsumableMail.uid = 0
            newAutoConsumableMail.addToTo(partnerId)
            newAutoConsumableMail.shortMessage = "auto-consumable"
            newAutoConsumableMail.longMessage = "auto-consumable"
            let header = CdHeaderField(context: moc)
            header.name = kPepHeaderAutoConsume
            header.value = kPepValueAutoConsumeYes
            newAutoConsumableMail.optionalFields = NSOrderedSet(array: [header])
            newMailsNotExpectedToBeCounted.append(newAutoConsumableMail)
        }
        // save
        moc.saveAndLogErrors()

        // upload to server ...
        appendMailsIMAP(folder: cdInbox,
                        imapConnection: imapConnection,
                        errorContainer: errorContainer,
                        queue: queue)
        // ... and fetch again
        guard let numNewMails = fetchNumberOfNewMails(errorContainer: errorContainer, context: moc)
            else {
                XCTFail()
                return
        }
        XCTAssertEqual(numNewMails, numNewMailsOrig + newMailsExpectedToBeCounted.count)
    }
}
