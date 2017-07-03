//
//  FetchFoldersServiceTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class FetchFoldersServiceTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!
    var cdAccountDisfunctional: CdAccount!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount

        let cdDisfunctionalAccount = TestData().createDisfunctionalCdAccount()
        cdDisfunctionalAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccountDisfunctional = cdDisfunctionalAccount
    }

    func runPrimitiveFetchFolders(shouldSucceed: Bool) {
        let foldersCount1 = (CdFolder.all() ?? []).count
        XCTAssertEqual(foldersCount1, 0)
        let expectationFoldersFetched = expectation(description: "expectationFoldersFetched")
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expectationFoldersFetched)
        let fetchService = FetchFoldersService(parentName: #function, backgrounder: mbg)

        guard let theCdAccount = shouldSucceed ? cdAccount : cdAccountDisfunctional else {
            XCTFail()
            return
        }
        guard let (imapSyncData, _) = TestUtil.syncData(cdAccount: theCdAccount) else {
            XCTFail()
            return
        }

        fetchService.execute(imapSyncData: imapSyncData) { error in
            if shouldSucceed {
                XCTAssertNil(error)
            } else {
                XCTAssertNotNil(error)
            }
        }

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }

        let foldersCount2 = (CdFolder.all() ?? []).count
        if shouldSucceed {
            XCTAssertGreaterThan(foldersCount2, foldersCount1)
        } else {
            XCTAssertEqual(foldersCount1, foldersCount1)
        }
    }

    func testPrimitiveFetchFoldersOK() {
        runPrimitiveFetchFolders(shouldSucceed: true)
    }

    func testPrimitiveFetchFoldersError() {
        runPrimitiveFetchFolders(shouldSucceed: false)
    }
}
