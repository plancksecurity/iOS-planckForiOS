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
}
