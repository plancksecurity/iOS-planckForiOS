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
    var acceptedLanguagesCodes: [String] = ["de", "en"]

    var keySyncEnabled: Bool = true

    var usePEPFolderEnabled: Bool = true

    var extraKeysEditable: Bool = true

    var unencryptedSubjectEnabled: Bool = true

    var threadedViewEnabled: Bool = true

    var passiveModeEnabled: Bool = true

    var defaultAccount: String? = "some@account.com"

    var lastKnownDeviceGroupState: DeviceGroupState = .grouped

    var shouldShowTutorialWizard: Bool = false

    var userHasBeenAskedForContactAccessPermissions: Bool = false

    var unsecureReplyWarningEnabled: Bool = false

    var verboseLogginEnabled: Bool = false

    // MARK: - MDM

    var mdmIsEnabled: Bool = false

    var mdmPEPPrivacyProtectionEnabled: Bool = false

    var mdmPEPExtraKeys: [[String:String]] = []

    var mdmPEPTrustwordsEnabled: Bool = false

    var mdmUnsecureDeliveryWarningEnabled: Bool = false

    var mdmPEPSyncFolderEnabled: Bool = false

    var mdmDebugLoggingEnabled: Bool = false

    var mdmAccountDisplayCount: Int = 1

    var mdmMaxPushFolders: Int = 1

    var mdmCompositionSenderName: String? = ""

    var mdmCompositionSignatureEnabled: Bool = false

    var mdmCompositionSignature: String? = ""

    var mdmCompositionSignatureBeforeQuotedMessage: String? = ""

    var mdmDefaultQuotedTextShown: Bool = false

    var mdmAccountDefaultFolders: [String : String] = ["":""]

    var mdmRemoteSearchEnabled: Bool = false

    var mdmAccountRemoteSearchNumResults: Int = 0

    var mdmPEPSaveEncryptedOnServerEnabled: Bool = false

    var mdmPEPSyncAccountEnabled: Bool = false

    var mdmPEPSyncNewDevicesEnabled: Bool = false


    var removeFolderViewCollapsedStateOfAccountWithExpectation: XCTestExpectation?
    // getters
    var collapsedStateForAccountWithAddressExpectation: XCTestExpectation?
    var collapsedStateForFolderOfAccountExpectation: XCTestExpectation?
    // setters
    var setFolderCollapsedStateExpectation: XCTestExpectation?
    var setAccountCollapsedStateExpectation: XCTestExpectation?

    let mdmEchoProtocolEnabled = false
    let mdmEchoProtocolInOutgoingMessageRatingPreviewEnabled = false

    let mdmMediaKeys = [[String:String]]()

    var isEnterprise = false

    init(verboseLogginEnabled: Bool) {
        self.verboseLogginEnabled = verboseLogginEnabled
    }

    init(removeFolderViewCollapsedStateOfAccountWithExpectation: XCTestExpectation? = nil,
         collapsedStateForAccountWithAddressExpectation: XCTestExpectation? = nil,
         collapsedStateForFolderOfAccountExpectation: XCTestExpectation? = nil,
         setFolderCollapsedStateExpectation: XCTestExpectation? = nil,
         setAccountCollapsedStateExpectation: XCTestExpectation? = nil) {
        self.removeFolderViewCollapsedStateOfAccountWithExpectation = removeFolderViewCollapsedStateOfAccountWithExpectation
        self.collapsedStateForAccountWithAddressExpectation = collapsedStateForAccountWithAddressExpectation
        self.collapsedStateForFolderOfAccountExpectation = collapsedStateForFolderOfAccountExpectation
        self.setFolderCollapsedStateExpectation = setFolderCollapsedStateExpectation
        self.setAccountCollapsedStateExpectation = setAccountCollapsedStateExpectation
    }


    // MARK: - Collapsing State

    func removeFolderViewCollapsedStateOfAccountWith(address: String) {
        fulfillIfNotNil(expectation: removeFolderViewCollapsedStateOfAccountWithExpectation)
    }

    func folderViewCollapsedState(forAccountWith address: String) -> Bool {
        fulfillIfNotNil(expectation: collapsedStateForAccountWithAddressExpectation)
        return true
    }

    func folderViewCollapsedState(forFolderNamed folderName: String, ofAccountWith address: String) -> Bool {
        fulfillIfNotNil(expectation: collapsedStateForFolderOfAccountExpectation)
        return true
    }

    func setFolderViewCollapsedState(forFolderNamed: String, ofAccountWith address: String, to value: Bool) {
        fulfillIfNotNil(expectation: setFolderCollapsedStateExpectation)
    }

    func setFolderViewCollapsedState(forAccountWith address: String, to value: Bool) {
        fulfillIfNotNil(expectation: setAccountCollapsedStateExpectation)
    }

    private func fulfillIfNotNil(expectation: XCTestExpectation?) {
        if expectation != nil {
            expectation?.fulfill()
        }
    }
}
