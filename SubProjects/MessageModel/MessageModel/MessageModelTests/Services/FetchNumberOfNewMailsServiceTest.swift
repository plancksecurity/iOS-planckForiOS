//
//  FetchNumberOfNewMailsServiceTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 29.12.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

final class FetchNumberOfNewMailsServiceTest: PersistentStoreDrivenTestBase {
    func testEndlessRunner() throws {
        guard let context = Stack.shared.mainContext else {
            XCTFail()
            return
        }

        guard let cdAccount = (CdAccount.all(in: context) as? [CdAccount])?.first else {
            XCTFail("No account to sync")
            return
        }

        let accountName = cdAccount.identityOrCrash.addressOrCrash

        syncAndWait(cdAccountsToSync: [cdAccount], context: context)

        while true {
            let errorContainer = ErrorPropagator.ErrorContainer()
            let numberOfNewMailsOptional = fetchNumberOfNewMails(errorContainer: errorContainer,
                                                                 context: context)

            guard let numberOfNewMails = numberOfNewMailsOptional else {
                XCTFail()
                return
            }

            XCTAssertFalse(errorContainer.hasErrors)

            print("**** new emails (\(accountName): \(numberOfNewMails)")

            Thread.sleep(forTimeInterval: 15.0)
        }
    }
}
