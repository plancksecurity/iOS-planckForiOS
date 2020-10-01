////  FetchNumberOfNewMailsServiceTest.swift
////  pEpForiOSTests
////
////  Created by Dirk Zimmermann on 16.11.18.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//
//import CoreData
//

import XCTest

import CoreData
import PEPObjCAdapterFramework

@testable import MessageModel

//!!!: must be moved to MM
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

    // MARK: - Normal Mails Only

    func testUnreadMail_normalOnly_one() {
        assertNewMailsService(numNewNormalMessages: 1, numNewAutoconsumableMessages: 0)
    }

    func testUnreadMail_normalOnly_two() {
        assertNewMailsService(numNewNormalMessages: 2, numNewAutoconsumableMessages: 0)
    }

    func testUnreadMail_normalOnly_many() {
        assertNewMailsService(numNewNormalMessages: 5, numNewAutoconsumableMessages: 0)
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

    // MARK: - Normal & Auto-Consumable Mails Exist

    func testUnreadMail_normalAndAutoconsumable_one() {
        assertNewMailsService(numNewNormalMessages: 1, numNewAutoconsumableMessages: 1)
    }

    func testUnreadMail_normalAndAutoconsumable_multi_sameCount() {
        assertNewMailsService(numNewNormalMessages: 2, numNewAutoconsumableMessages: 2)
    }

    func testUnreadMail_normalAndAutoconsumable_multi_lessNormal() {
        assertNewMailsService(numNewNormalMessages: 1, numNewAutoconsumableMessages: 2)
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
            let newNormalMail = CdMessage(context: moc) //!!!: replace with TestuTil.createCdMessage after this file has been moved to MM
            newNormalMail.uuid = UUID().uuidString
            newNormalMail.uid = 0
            newNormalMail.parent = cdInbox
            newNormalMail.addToTo(partnerId)
            newNormalMail.shortMessage = "Are you ok?"
            newNormalMail.longMessage = "Hi there!"
            newMailsExpectedToBeCounted.append(newNormalMail)
        }

        // Create new autoconsumable mails
        for _ in 0..<numNewAutoconsumableMessages {
            let newAutoConsumableMail = CdMessage(context: moc)//!!!: replace with TestuTil.createCdMessage after this file has been moved to MM
            newAutoConsumableMail.uuid = UUID().uuidString
            newAutoConsumableMail.uid = 0
            newAutoConsumableMail.parent = cdInbox
            newAutoConsumableMail.addToTo(partnerId)
            //
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
