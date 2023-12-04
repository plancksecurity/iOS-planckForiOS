//
//  AppSettings+UserSettingsProtocol.swift
//  pEp
//
//  Created by Martín Brude on 30/8/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
import PlanckToolboxForExtensions
#else
import MessageModel
import PlanckToolbox
#endif

extension AppSettings: UserSettingsProtocol {

    static let keyKeySyncEnabled = "keyStartpEpSync"
    static let keyUsePEPFolderEnabled = "keyUsePEPFolderEnabled"
    static let keyUnencryptedSubjectEnabled = "keyUnencryptedSubjectEnabled"
    static let keyDefaultAccountAddress = "keyDefaultAccountAddress"
    static let keyThreadedViewEnabled = "keyThreadedViewEnabled"
    static let keyPassiveMode = "keyPassiveMode"
    static let keyLastKnowDeviceGroupStateRawValue = "keyLastKnowDeviceGroupStateRawValue"
    static let keyExtraKeysEditable = "keyExtraKeysEditable"
    static let keyUserHasBeenAskedForContactAccessPermissions = "keyUserHasBeenAskedForContactAccessPermissions"
    static let keyUnsecureReplyWarningEnabled = "keyUnsecureReplyWarningEnabled"
    static let keyAccountSignature = "keyAccountSignature"
    static let keyVerboseLogginEnabled = "keyVerboseLogginEnabled"
    static let keyCollapsingState = "keyCollapsingState"
    static let keyFolderViewAccountCollapsedState = "keyFolderViewAccountCollapsedState-162844EB-1F32-4F66-8F92-9B77664523F1"
    static let keyAcceptedLanguagesCodes = "acceptedLanguagesCodes"

    static let keyAuditLoggingTime = "keyAuditLogTime"
    static let keyKeySyncWizardWasShown = "keyKeySyncWizardWasShown"
    static let keyPlanckSyncActivityIndicator = "keyPlanckSyncActivityIndicator"


    /// This structure keeps the collapsing state of folders and accounts.
    /// [AccountAddress: [ key: isCollapsedStatus ] ]
    ///
    /// For example:
    /// ["some@example.com": [ keyFolderViewAccountCollapsedState: true ] ] indicates the account is collapsed. Do not change the key keyFolderViewAccountCollapsedState
    /// ["some@example.com": [ "SomeFolderName": true ] ] indicates the folder is collapsed.
    private typealias CollapsingState = [String: [String: Bool]]

    public var keyPlanckSyncActivityIndicatorIsOn: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyPlanckSyncActivityIndicator)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPlanckSyncActivityIndicator)
            DispatchQueue.main.async {
                // inform views that display settings related data
                NotificationCenter.default.post(name:.planckSyncActivityIndicatorChanged, object: nil, userInfo: nil)
            }
        }
    }

    public var keySyncEnabled: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyKeySyncEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyKeySyncEnabled)
            stateChangeHandler?(newValue)
        }
    }

    // Time in days of the audit loggin file.
    public var auditLoggingTime: Int {
        get {
            return AppSettings.userDefaults.integer(forKey: AppSettings.keyAuditLoggingTime)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyAuditLoggingTime)
        }
    }

    // Indicate if the keySyncWizard was shown
    public var keySyncWizardWasShown: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyKeySyncWizardWasShown)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyKeySyncWizardWasShown)
        }
    }

    
    public var usePEPFolderEnabled: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyUsePEPFolderEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue,
                                         forKey: AppSettings.keyUsePEPFolderEnabled)
        }
    }

    public var extraKeysEditable: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyExtraKeysEditable)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyExtraKeysEditable)
        }
    }

    public var unencryptedSubjectEnabled: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyUnencryptedSubjectEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue,
                                         forKey: AppSettings.keyUnencryptedSubjectEnabled)
            MessageModelConfig.setUnEncryptedSubjectEnabled(newValue)
        }
    }

    public var threadedViewEnabled: Bool {
        get {
            return false
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyThreadedViewEnabled)
        }
    }

    public var passiveModeEnabled: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyPassiveMode)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPassiveMode)
            MessageModelConfig.setPassiveModeEnabled(newValue)
        }
    }

    public var userHasBeenAskedForContactAccessPermissions: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyUserHasBeenAskedForContactAccessPermissions)
        }
        set {
            AppSettings.userDefaults.set(newValue,
                                         forKey: AppSettings.keyUserHasBeenAskedForContactAccessPermissions)
        }
    }

    /// Address of the default account
    public var defaultAccount: String? {
        get {
            assureDefaultAccountIsSetAndExists()
            return AppSettings.userDefaults.string(forKey: AppSettings.keyDefaultAccountAddress)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyDefaultAccountAddress)
        }
    }

    public var lastKnownDeviceGroupState: DeviceGroupState {
        get {
            let rawValue = AppSettings.userDefaults.integer(forKey: AppSettings.keyLastKnowDeviceGroupStateRawValue)
            return DeviceGroupState(rawValue: rawValue) ?? DeviceGroupState.sole
        }
        set {
            AppSettings.userDefaults.set(newValue.rawValue,
                                         forKey: AppSettings.keyLastKnowDeviceGroupStateRawValue)
        }
    }

    public var unsecureReplyWarningEnabled: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyUnsecureReplyWarningEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue,
                                         forKey: AppSettings.keyUnsecureReplyWarningEnabled)
        }
    }

    public func setSignature(_ signature: String, forAddress address: String) {
        var signaturesForAdresses = signatureAddresDictionary
        signaturesForAdresses[address] = signature
        signatureAddresDictionary = signaturesForAdresses
    }

    public func signature(forAddress address: String?) -> String {
        guard let safeAddress = address else {
            return String.planckSignature
        }
        return signatureAddresDictionary[safeAddress] ?? String.planckSignature
    }

    public var verboseLogginEnabled: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyVerboseLogginEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue,
                                         forKey: AppSettings.keyVerboseLogginEnabled)
            Log.shared.verboseLoggingEnabled = newValue
        }
    }

    public var acceptedLanguagesCodes: [String] {
        get {
            guard let codes = AppSettings.userDefaults.object(forKey: AppSettings.keyAcceptedLanguagesCodes) as? [String] else {
                return []
            }
            return codes
        }
        set {
            return AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyAcceptedLanguagesCodes)
        }
    }
}

extension AppSettings {

    // MARK: - Setters

    public func setFolderViewCollapsedState(forAccountWith address: String, to value: Bool) {
        var current = collapsingState
        let key = AppSettings.keyFolderViewAccountCollapsedState
        if var currentAddress = current[address] {
            currentAddress[key] = value
            current[address] = currentAddress
        } else {
            current[address] = [key: value]
        }

        collapsingState = current
    }

    public func setFolderViewCollapsedState(forFolderNamed folderName: String, ofAccountWith address: String, to value: Bool) {
        var current = collapsingState
        if var currentAddressState = current[address] {
            currentAddressState[folderName] = value
            current[address] = currentAddressState
        } else {
            current[address] = [folderName: value]
        }
        collapsingState = current
    }

    public func removeFolderViewCollapsedStateOfAccountWith(address: String) {
        var current = collapsingState
        current[address] = nil
        collapsingState = current
    }

    // MARK: - Getters

    public func folderViewCollapsedState(forAccountWith address: String) -> Bool {
        let key = AppSettings.keyFolderViewAccountCollapsedState
        guard let state = collapsingState[address] else {
            //Valid case: might not been saved yet.
            return false
        }
        // If the value is not found, it wasn't collapsed.
        let isCollapsed: Bool = state[key] ?? false
        return isCollapsed
    }

    public func folderViewCollapsedState(forFolderNamed folderName: String, ofAccountWith address: String) -> Bool {
        guard let state = collapsingState[address] else {
            //Valid case: might not been saved yet.
            return false
        }
        // If the value is not found, it wasn't collapsed.
        let isCollapsed = state[folderName] ?? false
        return isCollapsed
    }
}

// MARK: - Private

extension AppSettings {

    private var signatureAddresDictionary: [String:String] {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: AppSettings.keyAccountSignature) as? [String:String] else {
                Log.shared.errorAndCrash(message: "Signature dictionary not found")
                return [String:String]()
            }
            return dictionary
        }
        set {
            AppSettings.userDefaults.set(newValue,
                                         forKey: AppSettings.keyAccountSignature)
        }
    }

    private var collapsingState: CollapsingState {
        get {
            guard let collapsingState = AppSettings.userDefaults.object(forKey: AppSettings.keyCollapsingState) as? CollapsingState else {
                // Valid case: there isn't a default value.
                return CollapsingState()
            }
            return collapsingState
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyCollapsingState)
        }
    }

    private func assureDefaultAccountIsSetAndExists() {
        if AppSettings.userDefaults.string(forKey: AppSettings.keyDefaultAccountAddress) == nil {
            // Default account is not set. Take the first MessageModel provides as a starting point
            let initialDefault = Account.all().first?.user.address
            AppSettings.userDefaults.set(initialDefault, forKey: AppSettings.keyDefaultAccountAddress)
        }
        // Assure the default account still exists. The user might have deleted it.
        guard
            let currentDefault = AppSettings.userDefaults.string(
                forKey: AppSettings.keyDefaultAccountAddress),
            let _ = Account.by(address: currentDefault)
            else {
                defaultAccount = nil
                return
        }
    }
}
