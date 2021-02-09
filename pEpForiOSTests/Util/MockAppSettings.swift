//
//  MockAppSettings.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 5/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest
@testable import pEpForiOS
@testable import MessageModel


class MockAppSettings: AppSettingsProtocol {

    var removeCollapsedStateOfAccountWithAddressExpectation: XCTestExpectation?
    // getters
    var collapsedStateForAccountWithAddressExpectation: XCTestExpectation?
    var collapsedStateForFolderOfAccountExpectation: XCTestExpectation?
    // setters
    var setFolderCollapsedStateExpectation: XCTestExpectation?
    var setAccountCollapsedStateExpectation: XCTestExpectation?

    init(verboseLogginEnabled: Bool) {
        self.verboseLogginEnabled = verboseLogginEnabled
    }

    init(removeCollapsedStateOfAccountWithAddressExpectation: XCTestExpectation? = nil,
         collapsedStateForAccountWithAddressExpectation: XCTestExpectation? = nil,
         collapsedStateForFolderOfAccountExpectation: XCTestExpectation? = nil,
         setFolderCollapsedStateExpectation: XCTestExpectation? = nil,
         setAccountCollapsedStateExpectation: XCTestExpectation? = nil) {
        self.removeCollapsedStateOfAccountWithAddressExpectation = removeCollapsedStateOfAccountWithAddressExpectation
        self.collapsedStateForAccountWithAddressExpectation = collapsedStateForAccountWithAddressExpectation
        self.collapsedStateForFolderOfAccountExpectation = collapsedStateForFolderOfAccountExpectation
        self.setFolderCollapsedStateExpectation = setFolderCollapsedStateExpectation
        self.setAccountCollapsedStateExpectation = setAccountCollapsedStateExpectation
    }

    var keySyncEnabled: Bool = true

    var usePEPFolderEnabled: Bool = true

    var extraKeysEditable: Bool = true

    var unencryptedSubjectEnabled: Bool = true

    var threadedViewEnabled: Bool = true

    var passiveMode: Bool = true

    var defaultAccount: String? = "some@account.com"

    var lastKnownDeviceGroupState: DeviceGroupState = .grouped

    var shouldShowTutorialWizard: Bool = false

    var userHasBeenAskedForContactAccessPermissions: Bool = false

    var unsecureReplyWarningEnabled: Bool = false

    var verboseLogginEnabled: Bool = false

    // MARK: - Collapsing State

    func removeCollapsedStateOfAccountWithAddress(address: String) {
        fulfillIfNotNil(expectation: removeCollapsedStateOfAccountWithAddressExpectation)
    }

    func collapsedState(forAccountWithAddress address: String) -> Bool {
        fulfillIfNotNil(expectation: collapsedStateForAccountWithAddressExpectation)
        return true
    }

    func folderViewCollapsedState(forFolderNamed folderName: String, ofAccountWithAddress address: String) -> Bool {
        fulfillIfNotNil(expectation: collapsedStateForFolderOfAccountExpectation)
        return true
    }

    func setFolderViewCollapsedState(forFolderNamed: String, ofAccountWithAddress address: String, to value: Bool) {
        fulfillIfNotNil(expectation: setFolderCollapsedStateExpectation)
    }

    func setCollapsedState(forAccountWithAddress address: String, to value: Bool) {
        fulfillIfNotNil(expectation: setAccountCollapsedStateExpectation)
    }

    private func fulfillIfNotNil(expectation: XCTestExpectation?) {
        if expectation != nil {
            expectation?.fulfill()
        }
    }
}
