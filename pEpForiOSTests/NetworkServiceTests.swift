//
//  NetworkServiceTests.swift
//  pEpForiOS
//
//  Created by hernani on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
import pEpForiOS

class NetworkServiceTests: XCTestCase {
    
    var persistenceSetup: PersistentSetup!
    
    let networkService = NetworkService()

    var cdAccount1: CdAccount!

    override func setUp() {
        super.setUp()
        
        persistenceSetup = PersistentSetup()
        cdAccount1 = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
    }
    
    override func tearDown() {
        persistenceSetup = nil
    }

    class NetworkServiceObserver: NetworkServiceDelegate {
        let expSingleAccountSynced: XCTestExpectation?
        var accountInfo: AccountConnectInfo?

        init(expAccountsSynced: XCTestExpectation? = nil) {
            self.expSingleAccountSynced = expAccountsSynced
        }

        func didSync(service: NetworkService, accountInfo: AccountConnectInfo) {
            if self.accountInfo == nil {
                self.accountInfo = accountInfo
                expSingleAccountSynced?.fulfill()
                service.cancel()
            }
        }
    }

    func testSyncOneTime() {
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))

        networkService.delegate = del
        networkService.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNotNil(del.accountInfo)
        XCTAssertNotNil(CdFolder.all())
        XCTAssertNotNil(CdMessage.all())
    }
}
