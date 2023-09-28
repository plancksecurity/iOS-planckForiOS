//
//  MockMDMAppSettings.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 22/8/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation
@testable import pEpForiOS
@testable import MessageModel

class MockRegularUsersAppSettings : AppSettingsProtocol {
    var keyPlanckSyncActivityIndicatorIsOn: Bool = false

    var mdmIsEnabled: Bool = false

    var keySyncEnabled: Bool = true

    var usePEPFolderEnabled: Bool = true

    var extraKeysEditable: Bool = true

    var unencryptedSubjectEnabled: Bool = true

    var threadedViewEnabled: Bool = true

    var passiveModeEnabled: Bool = true

    var defaultAccount: String? = ""

    var lastKnownDeviceGroupState: DeviceGroupState = .sole

    var userHasBeenAskedForContactAccessPermissions: Bool = true

    var unsecureReplyWarningEnabled: Bool = true

    var verboseLogginEnabled: Bool = true

    var acceptedLanguagesCodes: [String] = ["de", "en"]

    var mdmPEPPrivacyProtectionEnabled: Bool {
        return true
    }

    var mdmPlanckExtraKeys: [[String:String]] {
        return [["key":"value"]]
    }

    var mdmPEPTrustwordsEnabled: Bool {
        return true
    }

    var mdmUnsecureDeliveryWarningEnabled: Bool {
        return true
    }

    var mdmPEPSyncFolderEnabled: Bool {
        return true
    }

    var mdmDebugLoggingEnabled: Bool {
        return true
    }

    var mdmAccountDisplayCount: Int {
        return 0
    }

    var mdmMaxPushFolders: Int {
        return 0
    }

    var mdmCompositionSenderName: String? {
        return ""
    }

    var mdmCompositionSignatureEnabled: Bool {
        return true
    }

    var mdmCompositionSignature: String? {
        return ""
    }

    var mdmCompositionSignatureBeforeQuotedMessage: String? {
        return ""
    }

    var mdmDefaultQuotedTextShown: Bool {
        return true
    }

    var mdmAccountDefaultFolders: [String : String] {
        return ["":""]
    }

    var mdmRemoteSearchEnabled: Bool {
        return true
    }

    var mdmAccountRemoteSearchNumResults: Int {
        return 0
    }

    var mdmPEPSaveEncryptedOnServerEnabled: Bool {
        return true
    }

    var mdmPEPSyncAccountEnabled: Bool {
        return true
    }

    var mdmPEPSyncNewDevicesEnabled: Bool {
        return true
    }

    let mdmEchoProtocolEnabled = false

    let mdmEchoProtocolInOutgoingMessageRatingPreviewEnabled = false

    let mdmMediaKeys = [[String:String]]()

    var isEnterprise = false

    func removeFolderViewCollapsedStateOfAccountWith(address: String) {
    }

    func folderViewCollapsedState(forAccountWith address: String) -> Bool {
        return true
    }

    func folderViewCollapsedState(forFolderNamed folderName: String, ofAccountWith address: String) -> Bool {
        return true
    }

    func setFolderViewCollapsedState(forFolderNamed folderName: String, ofAccountWith address: String, to value: Bool) {

    }

    func setFolderViewCollapsedState(forAccountWith address: String, to value: Bool) {
    }
}

