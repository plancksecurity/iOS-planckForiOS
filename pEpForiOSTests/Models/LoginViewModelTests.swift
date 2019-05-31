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
import PantomimeFramework
import PEPObjCAdapterFramework

class NoOpMySelfer: KickOffMySelfProtocol {
    func startMySelf() {
        // do nothing
    }
}

class ErrorHandler: LoginViewModelLoginErrorDelegate {
    func handle(loginError: Error) {
        XCTFail("Error: \(loginError)")
    }
}

class LoginViewModelTests: CoreDataDrivenTestBase {
    /// We need a MMS for the login view model, and don't want to slip this out of scope.
    var fakeMessageModelService: MessageModelService? = nil

    class TestVerifiableAccount: VerifiableAccountProtocol {
        let accountSettings: TestDataBase.AccountSettings
        let expLookedUp: XCTestExpectation

        init(accountSettings: TestDataBase.AccountSettings, expLookedUp: XCTestExpectation) {
            self.accountSettings = accountSettings
            self.expLookedUp = expLookedUp
        }

        var address: String?
        var userName: String?
        var loginName: String?
        var authMethod: AuthMethod?
        var password: String?
        var accessToken: OAuth2AccessTokenProtocol?
        var serverIMAP: String?
        var portIMAP: UInt16 = 993
        var transportIMAP: ConnectionTransport = .TLS
        var serverSMTP: String?
        var portSMTP: UInt16 = 587
        var transportSMTP: ConnectionTransport = .startTLS
        var isAutomaticallyTrustedImapServer = false
        var isManuallyTrustedImapServer = false
        var verifiableAccountDelegate: VerifiableAccountDelegate?

        let isValidName = false

        let isValidUser = false

        func verify() throws {
            XCTAssertEqual(address, accountSettings.idAddress)

            XCTAssertEqual(transportIMAP,
                           ConnectionTransport(transport: accountSettings.imapServerTransport))
            XCTAssertEqual(portIMAP, accountSettings.imapServerPort)
            XCTAssertEqual(serverIMAP, accountSettings.imapServerAddress)

            XCTAssertEqual(transportSMTP,
                           ConnectionTransport(transport: accountSettings.smtpServerTransport))
            XCTAssertEqual(portSMTP, accountSettings.smtpServerPort)
            XCTAssertEqual(serverSMTP, accountSettings.smtpServerAddress)

            expLookedUp.fulfill()
        }

        func save() throws {
        }
    }

    /// This tests makes sense only if the server settings 
    /// in TestData.createWorkingAccountSettings == Accountsettingsadapter recommended server settings.
    /// Otherwize the test always succeeds.
    func testBasic() {
        let td = SecretTestData()
        let accountSettings = td.createVerifiableAccountSettings()
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

        let expLookedUp = expectation(description: "expLookedUp")
        let verifiableAccount =
            TestVerifiableAccount(accountSettings: accountSettings, expLookedUp: expLookedUp)

        let fakeMessageModelService = MessageModelService(
            notifyHandShakeDelegate: ErrorNotifyHandshakeDelegate())
        self.fakeMessageModelService = fakeMessageModelService

        let vm = LoginViewModel(messageModelService: fakeMessageModelService,
                                verifiableAccount: verifiableAccount)
        let errorHandler = ErrorHandler()
        vm.loginViewModelLoginErrorDelegate = errorHandler
        vm.login(accountName: accountSettings.idAddress,
                 userName: "User Name",
                 loginName: nil,
                 password: passw,
                 mySelfer: NoOpMySelfer())

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }
}

// MARK: - Helpers

class ErrorNotifyHandshakeDelegate: NSObject, PEPNotifyHandshakeDelegate {
    func notifyHandshake(_ object: UnsafeMutableRawPointer?,
                         me: PEPIdentity,
                         partner: PEPIdentity,
                         signal: PEPSyncHandshakeSignal) -> PEPStatus {
        return .unknownError
    }
}
