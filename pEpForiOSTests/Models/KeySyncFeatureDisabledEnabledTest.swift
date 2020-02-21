//
//  KeySyncFeatureDisabledEnabledTest.swift
//  pEpForiOSTests
//
//  Created by Adam Kowalski on 21/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel
import PantomimeFramework

// Related to bugfix for IOS-2019
class KeySyncFeatureDisabledEnabledTest: XCTestCase {

    let isKeySyncEnabled = KeySyncUtil.isKeySyncEnabled
    var accountSettings: TestDataBase.AccountSettings!
    var verifiableAccount: TestVerifiableAccount!

    override func setUp() {
        let td = SecretTestData()
        accountSettings = td.createVerifiableAccountSettings()
    }

    override func tearDown() {
        isKeySyncEnabled ? KeySyncUtil.enableKeySync() : KeySyncUtil.disableKeySync()
    }

    func testKeySyncDisabledGlobalPepSync() {

        let expLookedUp = expectation(description: "expLookedUp")
        verifiableAccount = TestVerifiableAccount(accountSettings: accountSettings, expLookedUp: expLookedUp)
        guard let passw = accountSettings.password else {
            XCTFail("expecting password for account")
            return
        }

        // pEpSync is turned off in Settings
        KeySyncUtil.disableKeySync()
        // user turn off pEpSync (default state) -> Login Screen
        verifiableAccount.keySyncEnable = false

        let sut = LoginViewModel(verifiableAccount: verifiableAccount)
        let errorHandler = ErrorHandler()
        sut.loginViewModelLoginErrorDelegate = errorHandler
        sut.login(emailAddress: accountSettings.idAddress,
                      displayName: "User Name",
                      password: passw)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in

            // expectation: pEpSync feature is turned off in Settings
            let settingsVM = SettingsViewModel(delegate: SettingsViewModelDelegateMock())
            let pEpSyncSectionData = settingsVM.items
                .filter { $0.type == .pEpSync }
            let pEpSyncRowData = pEpSyncSectionData.first?.rows
                .filter { $0.identifier == .pEpSync }.first
            let pEpSyncSwitchRow = pEpSyncRowData as? SettingsViewModel.SwitchRow

            guard let pEpSyncSwitchRowEnabled = pEpSyncSwitchRow?.isOn else {
                XCTFail()
                return
            }

            XCTAssertNil(error, "Account verification failed!")
            XCTAssertFalse(pEpSyncSwitchRowEnabled, "pEpSyncSwitch should be switched off!")
        })
    }

    func testKeySyncEnabledGlobalPepSync() {

        let expLookedUp = expectation(description: "expLookedUp")
        verifiableAccount = TestVerifiableAccount(accountSettings: accountSettings, expLookedUp: expLookedUp)
        guard let passw = accountSettings.password else {
            XCTFail("expecting password for account")
            return
        }

        // pEpSync is turned off in Settings
        KeySyncUtil.disableKeySync()
        // user turn on pEpSync (default state) -> Login Screen
        verifiableAccount.keySyncEnable = true

        let vmLogin = LoginViewModel(verifiableAccount: verifiableAccount)
        let errorHandler = ErrorHandler()
        vmLogin.loginViewModelLoginErrorDelegate = errorHandler
        vmLogin.login(emailAddress: accountSettings.idAddress,
                      displayName: "User Name",
                      password: passw)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in

            // expectation: pEpSync feature is turned on in Settings
            let vmSettings = SettingsViewModel(delegate: SettingsViewModelDelegateMock())
            let pEpSyncSectionData = vmSettings.items
                .filter { $0.type == .pEpSync }
            let pEpSyncRowData = pEpSyncSectionData.first?.rows
                .filter { $0.identifier == .pEpSync }.first
            let pEpSyncSwitchRow = pEpSyncRowData as? SettingsViewModel.SwitchRow

            guard let pEpSyncSwitchRowEnabled = pEpSyncSwitchRow?.isOn else {
                XCTFail("unable to find pEpSyncSwitchRow.isOn!")
                return
            }

            XCTAssertNil(error, "Account verification failed!")
            XCTAssertTrue(pEpSyncSwitchRowEnabled, "pEpSyncSwitch should be switched on!")
        })
    }

    class TestVerifiableAccount: VerifiableAccountProtocol {
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

        func save(completion: ((Bool)->())? ) throws {
        }
    }

}

// MARK: - delegate mocks

class SettingsViewModelDelegateMock: SettingsViewModelDelegate {
    func showLoadingView() { }
    func hideLoadingView() { }
    func showExtraKeyEditabilityStateChangeAlert(newValue: String) { }
}
