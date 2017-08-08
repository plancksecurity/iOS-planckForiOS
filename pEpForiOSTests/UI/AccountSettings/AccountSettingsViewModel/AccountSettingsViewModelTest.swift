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

    func testUpdate() {
        guard let cdServerCount = cdAccount.servers?.count else {
            XCTFail()
            return
        }
        let numServersBefore = cdServerCount

        let account = Account.from(cdAccount: cdAccount)

        guard let serverCount = account.servers?.count else {
            XCTFail()
            return
        }
        XCTAssertEqual(numServersBefore, serverCount)

        let testLoginName = "testLoginName"
        let testName = "testName"
        let testServerAddress = "my.test.address.org"
        let testPort = "666"
        let testTransport = Server.Transport.plain

        let newServerData =
            AccountSettingsViewModel.ServerViewModel(address: testServerAddress,
                                                     port: testPort,
                                                     transport: testTransport.asString())
        let testee = AccountSettingsViewModel(account: account)

        testee.update(loginName: testLoginName, name: testName, imap: newServerData,
                      smtp: newServerData)

        //Account updated
        XCTAssertEqual(numServersBefore, account.servers?.count)
        XCTAssertEqual(account.user.userName, testName)

        guard let servers = account.servers,
            let testPortInt = UInt16(testPort) else {
                XCTFail()
                return
        }
        for server in servers {
            if server.serverType == .imap || server.serverType == .smtp {
                XCTAssertEqual(server.address, testServerAddress)
                XCTAssertEqual(server.port, testPortInt)
                XCTAssertEqual(server.transport, testTransport)
            }
        }

        //CdAccount also updated
        guard let cdServers = cdAccount.servers?.allObjects as? [CdServer] else {
            XCTFail()
            return
        }
        XCTAssertEqual(numServersBefore, cdAccount.servers?.count)
        XCTAssertEqual(cdAccount.identity?.userName, testName)

        for cdServer in cdServers {
            guard let cdPort = cdServer.port else {
                XCTFail()
                return
            }
            if cdServer.serverType == .imap || cdServer.serverType == .smtp {
                XCTAssertEqual(cdServer.address, testServerAddress)
                XCTAssertEqual(UInt16(cdPort), testPortInt)
                XCTAssertEqual(cdServer.transport, testTransport)
            }
        }
    }
}
