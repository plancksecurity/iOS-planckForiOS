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

class ErrorHandler: LoginViewModelLoginErrorDelegate {
    func handle(loginError: Error) {
        XCTFail("Error: \(loginError)")
    }
}

class LoginViewModelTests: CoreDataDrivenTestBase {
    class TestVerifiableAccount: VerifiableAccountProtocol {

        var accountType: VerifiableAccount.AccountType = VerifiableAccount.AccountType.other
        var loginNameIMAP: String?

        var loginNameSMTP: String?

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
        var clientCertificate: ClientCertificate?
        var serverIMAP: String?
        var portIMAP: UInt16 = 993
        var transportIMAP: ConnectionTransport = .TLS
        var serverSMTP: String?
        var portSMTP: UInt16 = 587
        var transportSMTP: ConnectionTransport = .startTLS
        var isAutomaticallyTrustedImapServer = false
        var isManuallyTrustedImapServer = false
        var verifiableAccountDelegate: VerifiableAccountDelegate?

        var keySyncEnable = false
        let loginNameIsValid = false

        let isValidUser = false

        var containsCompleteServerInfo: Bool = false

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

        func save(completion: @escaping (Result<Void, Error>) -> ()) {
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

        let vm = LoginViewModel(verifiableAccount: verifiableAccount)
        let errorHandler = ErrorHandler()
        vm.loginViewModelLoginErrorDelegate = errorHandler
        vm.login(emailAddress: accountSettings.idAddress,
                 displayName: "User Name",
                 password: passw)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }
}
