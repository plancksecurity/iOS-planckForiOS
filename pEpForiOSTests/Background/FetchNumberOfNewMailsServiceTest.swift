//
//  FetchNumberOfNewMailsServiceTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 16.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
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

    func testBaseCase() {
        loginIMAP(imapSyncData: imapSyncData, errorContainer: errorContainer, queue: queue)
        fetchFoldersIMAP(imapSyncData: imapSyncData, queue: queue)

        guard let numNewMail = fetchNumberOfNewMails(errorContainer: errorContainer) else {
            XCTFail()
            return
        }
        XCTAssertEqual(numNewMail, 0)
    }

    func testUnreadMail() {
        loginIMAP(imapSyncData: imapSyncData, errorContainer: errorContainer, queue: queue)
        fetchFoldersIMAP(imapSyncData: imapSyncData, queue: queue)

        guard let numNewMailsOrig = fetchNumberOfNewMails(errorContainer: errorContainer) else {
            XCTFail()
            return
        }

        guard let inbox = Folder.by(account: account, folderType: .inbox) else {
            XCTFail()
            return
        }

        let partnerId = Identity(address: "somepartner@example.com",
                                 userID: "ID_somepartner@example.com",
                                 addressBookID: nil,
                                 userName: "USER_somepartner@example.com",
                                 isMySelf: false)

        let mail1 = Message(uuid: "message_1", uid: 0, parentFolder: inbox)
        mail1.from = account.user
        mail1.to = [partnerId]
        mail1.shortMessage = "Are you ok?"
        mail1.longMessage = "Hi there!"
        mail1.save()

        appendMailsIMAP(folder: inbox,
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
