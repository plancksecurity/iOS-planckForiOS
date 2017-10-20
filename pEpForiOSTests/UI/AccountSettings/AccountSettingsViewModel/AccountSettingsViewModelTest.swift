//
//  AccountSettingsViewModelTest.swift
//  pEpForiOS
//
//  Created by buff on 04.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData
import MessageModel
@testable import pEpForiOS

class AccountSettingsViewModelTest: CoreDataDrivenTestBase {
    var mss : MessageSyncService?

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        mss?.cancel()
        mss = nil
        super.tearDown()
    }

    class TestAccountVerificationDelegate: AccountVerificationResultDelegate {
        let expAccountVerified: XCTestExpectation
        var verificationResult: AccountVerificationResult?

        func didVerify(result: AccountVerificationResult) {
            self.verificationResult = result
            expAccountVerified.fulfill()
        }

        init(expAccountVerified: XCTestExpectation) {
            self.expAccountVerified = expAccountVerified
        }
    }
    
//    func testUpdate() {
//        mss = MessageSyncService(sleepTimeInSeconds: 2, backgrounder: nil, mySelfer: nil)
//        
//        guard let cdServerCount = cdAccount.servers?.count else {
//            XCTFail()
//            return
//        }
//        let numServersBefore = cdServerCount
//
//        let account = Account.from(cdAccount: cdAccount)
//
//        guard let serverCount = account.servers?.count else {
//            XCTFail()
//            return
//        }
//        XCTAssertEqual(numServersBefore, serverCount)
//
//        let testLoginName = "testLoginName"
//        let testName = "testName"
//        let testServerAddress = "my.test.address.org"
//        let testPort = "666"
//        let testTransport = Server.Transport.plain
//
//        let newServerData =
//            AccountSettingsViewModel.ServerViewModel(address: testServerAddress,
//                                                     port: testPort,
//                                                     transport: testTransport.asString())
//        let expVerified = expectation(description: "expVerified")
//        let accvef = TestAccountVerificationDelegate(expAccountVerified: expVerified)
//
//        let testee = AccountSettingsViewModel(account: account)
//        testee.messageSyncService = mss
//        testee.delegate = accvef
//
//        testee.update(loginName: testLoginName, name: testName, imap: newServerData,
//                      smtp: newServerData)
//
//        waitForExpectations(timeout: TestUtil.waitTime) { error in
//            XCTAssertNil(error)
//        }
//
//        guard let result = accvef.verificationResult else {
//            XCTFail()
//            return
//        }
//        switch result {
//        case .ok:
//            break
//        default:
//            XCTFail("Unexpected verification result: \(result)")
//        }
//
//        //Account updated
//        XCTAssertEqual(numServersBefore, account.servers?.count)
//        XCTAssertEqual(account.user.userName, testName)
//
//        guard let servers = account.servers,
//            let testPortInt = UInt16(testPort) else {
//                XCTFail()
//                return
//        }
//        for server in servers {
//            if server.serverType == .imap || server.serverType == .smtp {
//                XCTAssertEqual(server.address, testServerAddress)
//                XCTAssertEqual(server.port, testPortInt)
//                XCTAssertEqual(server.transport, testTransport)
//            }
//        }
//
//        //CdAccount also updated
//        guard let cdServers = cdAccount.servers?.allObjects as? [CdServer] else {
//            XCTFail()
//            return
//        }
//        XCTAssertEqual(numServersBefore, cdAccount.servers?.count)
//        XCTAssertEqual(cdAccount.identity?.userName, testName)
//
//        for cdServer in cdServers {
//            guard let cdPort = cdServer.port else {
//                XCTFail()
//                return
//            }
//            if cdServer.serverType == .imap || cdServer.serverType == .smtp {
//                XCTAssertEqual(cdServer.address, testServerAddress)
//                XCTAssertEqual(UInt16(truncating:cdPort), testPortInt)
//                XCTAssertEqual(cdServer.transport, testTransport)
//            }
//        }
//    }
}
