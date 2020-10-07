//
//  FetchImapFolderTest.swift
//  MessageModelTests
//
//  Created by Xavier Algarra on 02/09/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
import pEpIOSToolbox

class FetchImapFolderTest: PersistentStoreDrivenTestBase {
    var a: CdAccount?
    override func setUp() {
        super.setUp()
        a = cdAccount
        XCTAssertNotNil(a)
    }

    func testFetchFolders() {
        guard let account = a else {
            XCTFail()
            return
        }
        let fetchComplete = expectation(description: "fetchComplete")
        guard let totalfolders = (account.folders?.array as? [CdFolder])?.count else {
            XCTFail()
            return
        }
        account.folders?.array.forEach { (folder) in
            guard let f = folder as? CdFolder else {
                XCTFail()
                return
            }
            moc.delete(f)
        }
        moc.saveAndLogErrors()
        //no folders for this account.
        XCTAssertEqual(account.folders?.count, 0)
        let fetchFolderService = FetchImapFoldersService()

        do {
            try fetchFolderService.runService(inAccounts: [account.account()]) { success in
                fetchComplete.fulfill()
            }
        } catch {
            guard let er = error as? FetchImapFoldersService.FetchError else {
                    Log.shared.errorAndCrash("Unexpected error")
                    return
            }
            switch er {
            case .accountNotFound:
                XCTFail()
            case .isFetching:
                XCTFail()
                // Alredy fetching do nothing
                break
            }
        }
        waitForExpectations(timeout: TestUtil.waitTime)
        guard let foldersAfterFetch = account.folders?.array as? [CdFolder] else {
            XCTFail()
            return
        }
        XCTAssertGreaterThan(foldersAfterFetch.count, totalfolders)

    }
}
