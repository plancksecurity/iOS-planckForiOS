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
        
        // Initialize Core Data layer.
        persistenceSetup = PersistentSetup()
        cdAccount1 = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
    }
    
    override func tearDown() {
        persistenceSetup = nil
    }

    class NetworkServiceObserver: NetworkServiceDelegate {
        let expAccountsSynced: XCTestExpectation?

        init(expAccountsSynced: XCTestExpectation? = nil) {
            self.expAccountsSynced = expAccountsSynced
        }

        func didSyncAllAccounts(service: NetworkService) {
            expAccountsSynced?.fulfill()
            service.cancel()
        }
    }

    func testSyncOneTime() {
        XCTAssertNil(CdFolder.all())

        let expSynced = expectation(description: "expSynced")
        let del = NetworkServiceObserver(expAccountsSynced: expSynced)

        networkService.delegate = del
        networkService.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNotNil(CdFolder.all())
}
}
