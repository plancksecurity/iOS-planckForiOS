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
        let numServersBefore = serverCount(account: cdAccount)

        let account = Account.from(cdAccount: cdAccount)

        XCTAssertEqual(numServersBefore, serverCount(account: account))

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
        XCTAssertEqual(numServersBefore, serverCount(account: account))
        XCTAssertEqual(account.user.userName, testName)
        for credential in account.serverCredentials.array {
            for server in credential.servers.array {
                if server.serverType == .imap || server.serverType == .smtp {
                    XCTAssertEqual(server.address, testServerAddress)
                    XCTAssertEqual(server.port, UInt16(testPort)!)
                    XCTAssertEqual(server.transport, testTransport)
                }
            }
        }

        //CdAccount also updated
        XCTAssertEqual(numServersBefore, serverCount(account: cdAccount))
        XCTAssertEqual(cdAccount.identity?.userName, testName)
        guard let cdCredentials = cdAccount.credentials?.array as? [CdServerCredentials] else {
                XCTFail()
                return
        }

        for credential in cdCredentials {
            guard let cdServers = credential.servers?.allObjects as? [CdServer] else {
                XCTFail()
                return
            }
            for server in cdServers {
                guard let cdPort = server.port else {
                    XCTFail()
                    return
                }

                if server.serverType == Server.ServerType.imap
                    || server.serverType == Server.ServerType.smtp {
                    XCTAssertEqual(server.address, testServerAddress)
                    XCTAssertEqual(Int16(cdPort), Int16(testPort)!)
                    XCTAssertEqual(server.transport, testTransport)
                }
            }
        }
    }
    
    //MARK: - HELPERS
    /// Returns the number of all servers assined to the Account, taking all credentials into account
    private func serverCount(account:Account) -> Int {
        var count = 0
        for credential in account.serverCredentials {
            count += credential.servers.count
        }

        return count
    }

    /// Returns the number of all servers assined to the CdAccount, taking all credentials into account
    private func serverCount(account:CdAccount) -> Int {
        var count = 0
        guard let cdCredentials = cdAccount.credentials?.array as? [CdServerCredentials] else {
            return count
        }

        for credential in cdCredentials {
            guard let cdServers = credential.servers?.allObjects as? [CdServer] else {
                XCTFail()
                continue
            }
           count += cdServers.count
        }
        return count
    }
}
