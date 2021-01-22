//
//  PrepareAccountForSavingServiceTest.swift
//  MessageModelTests
//
//  Created by Xavier Algarra on 27/06/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS

class PrepareAccountForSavingServiceTest: PersistentStoreDrivenTestBase {

    func testBasicSuccess() {
        let expAccountPrepared = expectation(description: "expAccountPrepared")
        let accountPreparationService = PrepareAccountForSavingService()

        let privateMoc = Stack.shared.newPrivateConcurrentContext
        privateMoc.performAndWait {
            let testee = SecretTestData().createWorkingCdAccount(context: privateMoc, number: 0)
            accountPreparationService.prepareAccount(cdAccount: testee,
                                                     pEpSyncEnable: true,
                                                     alsoCreatePEPFolder: false,
                                                     context: privateMoc) {
                success in
                XCTAssertTrue(success)
                expAccountPrepared.fulfill()
            }
        }
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testBasicFailure() {
        let expAccountPrepared = expectation(description: "expAccountPrepared")
        let accountPreparationService = PrepareAccountForSavingService()

        let privateMoc = Stack.shared.newPrivateConcurrentContext
        privateMoc.performAndWait {
            let testee = SecretTestData().createImapTimeOutCdAccount(context: privateMoc)
            accountPreparationService.prepareAccount(cdAccount: testee,
                                                     pEpSyncEnable: true,
                                                     alsoCreatePEPFolder: false,
                                                     context: moc) {
                success in
                XCTAssertFalse(success)
                expAccountPrepared.fulfill()
            }
        }
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testRequiredFoldersAreCreated() {
        let expAccountPrepared = expectation(description: "expAccountPrepared")
        let accountPreparationService = PrepareAccountForSavingService()
        let privateMoc = Stack.shared.newPrivateConcurrentContext
        var testee : CdAccount? = nil
        privateMoc.performAndWait {
            testee = SecretTestData().createWorkingCdAccount(context: privateMoc, number: 0)
            guard let testacc = testee else {
                XCTFail()
                return
            }
            accountPreparationService.prepareAccount(cdAccount: testacc,
                                                     pEpSyncEnable: true,
                                                     alsoCreatePEPFolder: false,
                                                     context: privateMoc) {
                success in
                XCTAssertTrue(success)
                expAccountPrepared.fulfill()
            }
        }
        waitForExpectations(timeout: TestUtil.waitTime)

        privateMoc.performAndWait {
            guard let folders = testee?.folders?.array as? [CdFolder] else {
                XCTFail()
                return
            }

            var requiredFolderTypes = Set(FolderType.requiredTypes)
            requiredFolderTypes.insert(FolderType.outbox)
            let createdFolderTypes = Set(folders.map { $0.folderType })
            let expectedMissingRquieredFolders = 0
            XCTAssertEqual(requiredFolderTypes.subtracting(createdFolderTypes).count,
                           expectedMissingRquieredFolders)
        }
    }

    func testKeysAreCorrectlyGenerated() {
        //another option: outgoin message to myself and check the outgoing color.
        let expAccountPrepared = expectation(description: "expAccountPrepared")
        let accountPreparationService = PrepareAccountForSavingService()
        let privateMoc = Stack.shared.newPrivateConcurrentContext
        var testee: CdAccount? = nil
        privateMoc.performAndWait {
            testee = SecretTestData().createWorkingCdAccount(context: privateMoc, number: 0)
            guard let testacc = testee else {
                XCTFail()
                return
            }
            accountPreparationService.prepareAccount(cdAccount: testacc,
                                                     pEpSyncEnable: true,
                                                     alsoCreatePEPFolder: false,
                                                     context: privateMoc) {
                success in
                XCTAssertTrue(success)
                expAccountPrepared.fulfill()
            }
        }
        self.waitForExpectations(timeout: TestUtil.waitTime)

        privateMoc.performAndWait {
            guard let cdIndentity = testee?.identity else {
                XCTFail()
                return
            }
            let pEpRating = rating(for: cdIndentity.pEpIdentity())
            XCTAssertEqual(pEpRating, PEPRating.trustedAndAnonymized)
        }
    }
}
