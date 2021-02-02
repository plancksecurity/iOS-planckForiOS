//
//  AppSettings.swift
//  pEp
//
//  Created by Dirk Zimmermann on 27.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox
import pEp4iosIntern

// MARK: - Keys

extension AppSettings {
    static private let keyKeySyncEnabled = "keyStartpEpSync"
    static private let keyUsePEPFolderEnabled = "keyUsePEPFolderEnabled"
    static private let keyUnencryptedSubjectEnabled = "keyUnencryptedSubjectEnabled"
    static private let keyDefaultAccountAddress = "keyDefaultAccountAddress"
    static private let keyThreadedViewEnabled = "keyThreadedViewEnabled"
    static private let keyPassiveMode = "keyPassiveMode"
    static private let keyLastKnowDeviceGroupStateRawValue = "keyLastKnowDeviceGroupStateRawValue"
    static private let keyExtraKeysEditable = "keyExtraKeysEditable"
    static private let keyShouldShowTutorialWizard = "keyShouldShowTutorialWizard"
    static private let keyUserHasBeenAskedForContactAccessPermissions = "keyUserHasBeenAskedForContactAccessPermissions"
    static private let keyUnsecureReplyWarningEnabled = "keyUnsecureReplyWarningEnabled"
    static private let keyAccountSignature = "keyAccountSignature"
    static private let keyVerboseLogginEnabled = "keyVerboseLogginEnabled"
    static private let keyCollapsingState = "keyCollapsingState"
    static private let keyAccountCollapstedState = "keyAccountCollapstedState"
}

// MARK: - AppSettings

/// Signleton representing and managing the App's settings.
public final class AppSettings: KeySyncStateProvider {

    /// This structure keeps the collapsing state of folders and accounts.
    /// [AccountAddress : [ FolderName : isCollapsedStatus ] ]
    ///
    /// For example:
    /// ["mb@pep.security" : [ "keyAccountCollapstedState" : true ] ] indicates the account is collapsed.
    /// ["mb@pep.security" : [ "SomeFolder" : true ] ] indicates the folder is collapsed.
    private typealias CollapsingState = [String: [String: Bool]]

    // MARK: - Singleton
    
    static public let shared = AppSettings()

    private init() {
        setup()
        registerForKeySyncDeviceGroupStateChangeNotification()
        registerForKeySyncDisabledByEngineNotification()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - KeySyncStateProvider

    public var stateChangeHandler: ((Bool) -> Void)?

    public var isKeySyncEnabled: Bool {
        return keySyncEnabled
    }
}

// MARK: - Private

extension AppSettings {

    static private var userDefaults: UserDefaults = {
        guard let appGroupDefaults = UserDefaults.init(suiteName: appGroupIdentifier) else {
            Log.shared.errorAndCrash("Could not find app group defaults")
            return UserDefaults.standard
        }
        return appGroupDefaults
    }()

    // MARK: - Setup

    private func setup() {
        registerDefaults()
        setupObjcAdapter()
    }

    private func setupObjcAdapter() {
        MessageModelConfig.setUnEncryptedSubjectEnabled(unencryptedSubjectEnabled)
        MessageModelConfig.setPassiveModeEnabled(passiveMode)
    }

    private func registerDefaults() {
        var defaults = [String: Any]()
        defaults[AppSettings.keyKeySyncEnabled] = true
        defaults[AppSettings.keyUsePEPFolderEnabled] = true
        defaults[AppSettings.keyUnencryptedSubjectEnabled] = false
        defaults[AppSettings.keyThreadedViewEnabled] = true
        defaults[AppSettings.keyPassiveMode] = false
        defaults[AppSettings.keyLastKnowDeviceGroupStateRawValue] = DeviceGroupState.sole.rawValue
        defaults[AppSettings.keyExtraKeysEditable] = false
        defaults[AppSettings.keyShouldShowTutorialWizard] = true
        defaults[AppSettings.keyUserHasBeenAskedForContactAccessPermissions] = false
        defaults[AppSettings.keyUnsecureReplyWarningEnabled] = false
        defaults[AppSettings.keyAccountSignature] = [String:String]()
        defaults[AppSettings.keyVerboseLogginEnabled] = false
        defaults[AppSettings.keyCollapsingState] = CollapsingState()
        AppSettings.userDefaults.register(defaults: defaults)
    }

    // MARK: - Other

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

// MARK: - AppSettingsProtocol

extension AppSettings: AppSettingsProtocol {
    public var keySyncEnabled: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyKeySyncEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue,
                                         forKey: AppSettings.keyKeySyncEnabled)
            stateChangeHandler?(newValue)
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

    public var passiveMode: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyPassiveMode)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPassiveMode)
            MessageModelConfig.setPassiveModeEnabled(newValue)
        }
    }

    public var shouldShowTutorialWizard: Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyShouldShowTutorialWizard)
        }
        set {
            AppSettings.userDefaults.set(newValue,
                                         forKey: AppSettings.keyShouldShowTutorialWizard)
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

    public func setSignature(_ signature: String, forAddress address: String) {
        var signaturesForAdresses = signatureAddresDictionary
        signaturesForAdresses[address] = signature
        signatureAddresDictionary = signaturesForAdresses
    }
    
    public func signature(forAddress address: String?) -> String {
        guard let safeAddress = address else {
            return String.pepSignature
        }
        return signatureAddresDictionary[safeAddress] ?? String.pepSignature
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
}

//MARK: Collapsing State

extension AppSettings {

    //MARK: Setters

    /// Handles Account collapsing state changed.
    /// - Parameters:
    ///   - address: The address of the account
    ///   - isCollapsed: The state, true if it's collapsed.
    public func handleAccountColapsedStateChange(address: String, isCollapsed: Bool) {
        var current = collapsingState
        let key = AppSettings.keyAccountCollapstedState
        current[address] = [key: isCollapsed]
        collapsingState = current
    }

    /// Handles the new collapsing state.
    /// - Parameter state: The collapsing state.
    public func handleFolderColapsedStateChange(address: String, folderName: String, isCollapsed: Bool) {
        var current = collapsingState
        if var currentAddressState = current[address] {
            currentAddressState[folderName] = isCollapsed
            current[address] = currentAddressState
        } else {
            current[address] = [folderName: isCollapsed]
        }

        collapsingState = current
    }

    public func handleFoldersColapsedStateChange(address: String, foldersName: [String], isCollapsed: Bool) {
        var current = collapsingState
        if var currentAddressState = current[address] {
            foldersName.forEach { (folderName) in
                currentAddressState[folderName] = isCollapsed
            }
            current[address] = currentAddressState
        } else {
            foldersName.forEach { (folderName) in
                current[address] = [folderName: isCollapsed]
            }
        }
        collapsingState = current
    }

    /// Handles the removal of the account.
    /// Removes preferences binded to the account.
    ///
    /// - Parameter address: The account email address.
    public func handleRemovalOfAccountWithAddress(address: String) {
        var current = collapsingState
        current[address] = nil
        collapsingState = current
    }

    //MARK: Getters

    public func collapsedState(forAccountWithAddress address: String) -> Bool {
        let key = AppSettings.keyAccountCollapstedState
        guard let state = collapsingState[address] else {
            //Valid case: might not been saved yet.
            return false
        }
        // If the value is not found, it wasn't collapsed.
        let isCollapsed: Bool = state[key] ?? false
        return isCollapsed
    }

    public func collapsedState(forFolderNamed folderName: String, ofAccountWithAddress address: String) -> Bool {
        guard let state = collapsingState[address] else {
            //Valid case: might not been saved yet.
            return false
        }
        // If the value is not found, it wasn't collapsed.
        let isCollapsed = state[folderName] ?? false
        return isCollapsed
    }

    private var collapsingState: CollapsingState {
        get {
            guard let collapsingState = AppSettings.userDefaults.object(forKey: AppSettings.keyCollapsingState) as? CollapsingState else {
                Log.shared.errorAndCrash("Can't cast collapsing state")
                return CollapsingState()
            }
            return collapsingState
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyCollapsingState)
        }
    }
}
