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
    class FetchFoldersServiceTestDelegate: FetchFoldersServiceDelegate {
        var createdFoldersCount = 0

        func didCreate(folder: Folder) {
            createdFoldersCount += 1
        }
    }

    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!
    var cdAccountDisfunctional: CdAccount!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = SecretTestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount

        let cdDisfunctionalAccount = SecretTestData().createDisfunctionalCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccountDisfunctional = cdDisfunctionalAccount
    }

    func runPrimitiveFetchFolders(shouldSucceed: Bool) {
        let foldersCount1 = (CdFolder.all() ?? []).count
        XCTAssertEqual(foldersCount1, 0)
        let expectationServiceRan = expectation(description: "expectationServiceRan")
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expectationServiceRan)

        guard let theCdAccount = shouldSucceed ? cdAccount : cdAccountDisfunctional else {
            XCTFail()
            return
        }
        guard let (imapSyncData, _) = TestUtil.syncData(cdAccount: theCdAccount) else {
            XCTFail()
            return
        }

        let fetchService = FetchFoldersService(
            parentName: #function, backgrounder: mbg, imapSyncData: imapSyncData)
        let fetchDelegate = FetchFoldersServiceTestDelegate()
        fetchService.delegate = fetchDelegate

        fetchService.execute() { error in
            if shouldSucceed {
                XCTAssertNil(error)
            } else {
                XCTAssertNotNil(error)
            }
        }

        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }

        let foldersCount2 = (CdFolder.all() ?? []).count
        if shouldSucceed {
            XCTAssertGreaterThan(fetchDelegate.createdFoldersCount, 0)
            XCTAssertGreaterThan(foldersCount2, foldersCount1)
        } else {
            XCTAssertEqual(fetchDelegate.createdFoldersCount, 0)
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
