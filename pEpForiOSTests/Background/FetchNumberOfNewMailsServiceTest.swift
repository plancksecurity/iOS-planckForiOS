//!!!: crashes. Should be fixed with using Cd* (not MM)
////
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

@testable import pEpForiOS
@testable import MessageModel

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

        guard let numNewMailsOrig = fetchNumberOfNewMails(errorContainer: errorContainer) else {
            XCTFail()
            return
        }

        guard let cdInbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        let partnerId = CdIdentity(context: moc)
        partnerId.address = "somepartner@example.com"
        partnerId.userID = "ID_somepartner@example.com"
        partnerId.addressBookID = nil
        partnerId.userName = "USER_somepartner@example.com"

        let mail1 = CdMessage(context: moc)
        mail1.uuid = MessageID.generateUUID(localPart: "testUnreadMail")
        mail1.uid = 0
        mail1.parent = cdInbox
        mail1.addToTo(partnerId)
        mail1.shortMessage = "Are you ok?"
        mail1.longMessage = "Hi there!"
        Record.saveAndWait()

        appendMailsIMAP(folder: cdInbox,
                        imapSyncData: imapSyncData,
                        errorContainer: errorContainer,
                        queue: queue)

        guard let numNewMails = fetchNumberOfNewMails(errorContainer: errorContainer) else {
            XCTFail()
            return
        }
        XCTAssertEqual(numNewMails, numNewMailsOrig + 1)
    }
}
