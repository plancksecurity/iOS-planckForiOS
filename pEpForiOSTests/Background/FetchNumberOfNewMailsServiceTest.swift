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

@testable import pEpForiOS
@testable import MessageModel

//!!!: must be moved to MM
class FetchNumberOfNewMailsServiceTest: CoreDataDrivenTestBase {
    var errorContainer: ServiceErrorProtocol!
    var queue: OperationQueue!

    override func setUp() {
        super.setUp()
        errorContainer = ErrorContainer()
        queue = OperationQueue()
    }

    func testUnreadMail() {
        loginIMAP(imapSyncData: imapSyncData, errorContainer: errorContainer, queue: queue)
        fetchFoldersIMAP(imapSyncData: imapSyncData, queue: queue)

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

        let mail1 = CdMessage(context: moc)
        mail1.uuid = MessageID.generateUUID(localPart: "testUnreadMail")
        mail1.uid = 0
        mail1.parent = cdInbox
        mail1.addToTo(partnerId)
        mail1.shortMessage = "Are you ok?"
        mail1.longMessage = "Hi there!"
        newMailsExpectedToBeCounted.append(mail1)

        let mailAutoConsumable = CdMessage(context: moc)
        mailAutoConsumable.uuid = MessageID.generateUUID(localPart: "testUnreadMail")
        mailAutoConsumable.uid = 0
        mailAutoConsumable.parent = cdInbox
        mailAutoConsumable.addToTo(partnerId)
        //
        mailAutoConsumable.shortMessage = "auto-consumable"
        mailAutoConsumable.longMessage = "auto-consumable"
        let header = CdHeaderField(context: moc)
        header.name = kPepHeaderAutoConsume
        header.value = kPepValueAutoConsumeYes
        mailAutoConsumable.optionalFields = NSOrderedSet(array: [header])
        newMailsNotExpectedToBeCounted.append(mailAutoConsumable)
        //
        moc.saveAndLogErrors()

        XCTAssertFalse(mail1.hasAutoConsumeHeader)
        XCTAssertTrue(mailAutoConsumable.hasAutoConsumeHeader)

        appendMailsIMAP(folder: cdInbox,
                        imapSyncData: imapSyncData,
                        errorContainer: errorContainer,
                        queue: queue)

        guard let numNewMails = fetchNumberOfNewMails(errorContainer: errorContainer, context: moc)
            else {
                XCTFail()
                return
        }
        //BUFF:
        print("BUFF: numNewMailsOrig: \(numNewMailsOrig) ## numNewMailsOrig / 2: \(numNewMailsOrig / 2)(UID)")
        print("BUFF: numNewMails: \(numNewMails) ## numNewMails / 2: \(numNewMails / 2)(UID)")
            //
        XCTAssertEqual(numNewMails, numNewMailsOrig + newMailsNotExpectedToBeCounted.count)
    }
}
