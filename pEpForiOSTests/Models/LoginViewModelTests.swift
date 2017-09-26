//
//  LoginViewModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class NoOpMySelfer: KickOffMySelfProtocol {
    func startMySelf() {
        // do nothing
    }
}

class LoginViewModelTests: XCTestCase {
    class TestMessageSyncService: MessageSyncServiceProtocol {
        weak var errorDelegate: MessageSyncServiceErrorDelegate?
        weak var sentDelegate: MessageSyncServiceSentDelegate?
        weak var syncDelegate: MessageSyncServiceSyncDelegate?
        weak var stateDelegate: MessageSyncServiceStateDelegate?
        weak var flagsUploadDelegate: MessageSyncFlagsUploadDelegate?

        let accountSettings: TestDataBase.AccountSettings

        init(accountSettings: TestDataBase.AccountSettings) {
            self.accountSettings = accountSettings
        }

        func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
            XCTAssertEqual(account.user.address, accountSettings.idAddress)
            guard let imapServer = account.imapServer else {
                XCTFail("expecting IMAP server")
                return
            }
            XCTAssertEqual(imapServer.transport, accountSettings.imapServerTransport)
            XCTAssertEqual(imapServer.port, accountSettings.imapServerPort)
            XCTAssertEqual(imapServer.address, accountSettings.imapServerAddress)

            guard let smtpServer = account.smtpServer else {
                XCTFail("expecting SMTP server")
                return
            }
            XCTAssertEqual(smtpServer.transport, accountSettings.smtpServerTransport)
            XCTAssertEqual(smtpServer.port, accountSettings.smtpServerPort)
            XCTAssertEqual(smtpServer.address, accountSettings.smtpServerAddress)
        }

        func requestFetchOlderMessages(inFolder folder: Folder) {
            XCTFail("unexpected call to \(#function)")
        }

        func requestDraft(message: Message) {
            XCTFail("unexpected call to \(#function)")
        }

        func requestSend(message: Message) {
            XCTFail("unexpected call to \(#function)")
        }

        func requestFlagChange(message: Message) {
            XCTFail("unexpected call to \(#function)")
        }

        func requestMessageSync(folder: Folder) {
            XCTFail("unexpected call to \(#function)")
        }

        func start(account: Account) {
            XCTFail("unexpected call to \(#function)")
        }

        func cancel(account: Account) {
            XCTFail("unexpected call to \(#function)")
        }
    }

    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    override func tearDown() {
        persistentSetup = nil
    }

    /// This tests makes sense only if the server settings 
    /// in TestData.createWorkingAccountSettings == Accountsettingsadapter recommended server settings.
    /// Otherwize the test always succeeds.
    func testBasic() {
        let td = TestData()
        let accountSettings = td.createWorkingAccountSettings()
        guard let passw = accountSettings.password else {
            XCTFail("expecting password for account")
            return
        }

        //FIXME: return if imap or smtp server settings in TestData.createWorkingAccountSettings differ from
        // Wait until propper type conversion in between the account settings (SettingsLib, Pantomime, Server.Transport) exist -> IOS-633
        // dirty workarount for so long:
        if accountSettings.idAddress.contains("yahoo") {
            return
        }
        // Accountsettingsadapter recommended server settings
//        let adapterRecomendations = ASAccountSettings(accountName: accountSettings.idAddress,
//                                                      provider: passw,
//                                                      flags: AS_FLAG_USE_ANY,
//                                                      credentials: nil)
//        // If Imap or SMTP server settings differ, this test makes no sense and we succeed and return.
//        guard accountSettings.imapServerPort == UInt16(adapterRecomendations.incoming.port),
//            accountSettings.imapServerTransport== Int16(ConnectionTransport(
//                accountSettingsTransport: adapterRecomendations.incoming.transport).rawValue),
//            accountSettings.imapServerAddress == adapterRecomendations.incoming.hostname,
//
//        accountSettings.smtpServerPort == UInt16(adapterRecomendations.outgoing.port),
//        accountSettings.smtpServerTransport.rawValue == Int16(ConnectionTransport(
//        accountSettingsTransport: adapterRecomendations.outgoing.transport).rawValue),
//            accountSettings.smtpServerAddress == adapterRecomendations.outgoing.hostname else {
//                return
//        }

        let ms = TestMessageSyncService(accountSettings: accountSettings)
        let vm = LoginViewModel(messageSyncService: ms)

        vm.login(account: accountSettings.idAddress, password: passw, login: nil, userName: nil,
                 mySelfer: NoOpMySelfer()) {
                    error in
                    XCTAssertNil(error)
        }
    }
}
