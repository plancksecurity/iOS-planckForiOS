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

    func testBasic() {
        let td = TestData()
        let accountSettings = td.createWorkingAccountSettings()
        let ms = TestMessageSyncService(accountSettings: accountSettings)
        let vm = LoginViewModel(messageSyncService: ms)
        guard let passw = accountSettings.password else {
            XCTFail("expecting password for account")
            return
        }
        vm.login(account: accountSettings.idAddress, password: passw, login: nil, userName: nil) {
            error in
            XCTAssertNil(error)
        }
    }
}
