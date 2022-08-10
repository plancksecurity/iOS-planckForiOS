//
//  AppSettings.swift
//  pEp
//
//  Created by Dirk Zimmermann on 27.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

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
    static private let keyFolderViewAccountCollapsedState = "keyFolderViewAccountCollapsedState-162844EB-1F32-4F66-8F92-9B77664523F1"
    static private let keyAcceptedLanguagesCodes = "acceptedLanguagesCodes"

    // MARK: - MDM Settings

    static private var keyPEPEnablePrivacyProtectionEnabled = "pep_enable_privacy_protection"
    static private var keyPEPExtraKeys = "pep_extra_keys"
    static private var keyPEPTrustwordsEnabled = "pep_use_trustwords"
    static private var keyUnsecureDeliveryWarningEnabled = "unsecure_delivery_warning"
    static private var keyPEPSyncFolderEnabled = "pep_sync_folder"
    static private var keyDebugLoggingEnabled = "debug_logging"
    static private var keyAccountDisplayCount = "account_display_count"
    static private var keyMaxPushFolders = "max_push_folders"
    static private var keyCompositionSenderName = "composition_sender_name"
    static private var keyCompositionSignatureEnabled = "composition_use_signature"
    static private var keyCompositionSignature = "composition_signature"
    static private var keyCompositionSignatureBeforeQuotedMessageEnabled = "composition_signature_before_quoted_message"
    static private var keyDefaultQuotedTextShownEnabled = "default_quoted_text_shown"
    static private var keyAccountDefaultFolders = "account_default_folders"
    static private var keyRemoteSearchEnabled = "remote_search_enabled"
    static private var keyAccountRemoteSearchNumResults = "account_remote_search_num_results"
    static private var keyPEPSaveEncryptedOnServerEnabled = "pep_save_encrypted_on_server"
    static private var keyPEPEnableSyncAccountEnabled = "pep_enable_sync_account"
    static private var keyPEPSyncNewDevicesEnabled = "allow_pep_sync_new_devices"
}

// MARK: - AppSettings

/// Signleton representing and managing the App's settings.
public final class AppSettings: KeySyncStateProvider {

    /// This structure keeps the collapsing state of folders and accounts.
    /// [AccountAddress : [ key : isCollapsedStatus ] ]
    ///
    /// For example:
    /// ["some@example.com" : [ keyFolderViewAccountCollapsedState : true ] ] indicates the account is collapsed. Do not change the key keyFolderViewAccountCollapsedState
    /// ["some@example.com" : [ "SomeFolderName" : true ] ] indicates the folder is collapsed.
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
        guard let appGroupDefaults = UserDefaults.init(suiteName: kAppGroupIdentifier) else {
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
        // TODO:
        // The languages restriction to English (en) and German (de) is clearly not the default.
        // It's only for one customer.
        // For the rest of the users all languages should be the default, that is nil.
        // When we can distinguish in code that specific customer fix it. 
        defaults[AppSettings.keyAcceptedLanguagesCodes] = ["de", "en"]

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

//MARK: Collapsing State

extension AppSettings {

    //MARK: Setters

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

    //MARK: Getters

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
}

// MARK: - MDM

extension AppSettings: MDMAppSettingsProtocol {

    public var mdmPEPPrivacyProtectionEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyPEPEnablePrivacyProtectionEnabled] as? Bool else {
                return false
            }
            return value
        }
    }

    public var mdmPEPExtraKeys : [String] {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyPEPExtraKeys] as? [String] else {
                return []
            }
            return value
        }
    }

    public var mdmPEPTrustwordsEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyPEPTrustwordsEnabled] as? Bool else {
                return false
            }
            return value
        }
    }

    public var mdmUnsecureDeliveryWarningEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyUnsecureDeliveryWarningEnabled] as? Bool else {
                return true
            }
            return value
        }
    }

    public var mdmPEPSyncFolderEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyPEPSyncFolderEnabled] as? Bool else {
                return false
            }
            return value
        }
    }

    public var mdmDebugLoggingEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyDebugLoggingEnabled] as? Bool else {
                //Default value
                return false
            }
            return value
        }
    }

    public var mdmAccountDisplayCount: Int {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyAccountDisplayCount] as? Int else {
                //Default value
                return 250
            }
            return value
        }
    }

    public var mdmMaxPushFolders : Int {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyMaxPushFolders] as? Int else {
                //Default value
                return 0
            }
            return value
        }
    }

    public var mdmCompositionSenderName : String? {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyCompositionSenderName] as? String else {
                return nil
            }
            return value
        }
    }

    public var mdmCompositionSignatureEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyCompositionSignatureEnabled] as? Bool else {
                //Default value
                return true
            }
            return value
        }
    }

    public var mdmCompositionSignature : String? {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyCompositionSignature] as? String else {
                return nil
            }
            return value
        }
    }

    public var mdmCompositionSignatureBeforeQuotedMessage : String? {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyCompositionSignatureBeforeQuotedMessageEnabled] as? String else {
                return nil
            }
            return value
        }
    }

    public var mdmDefaultQuotedTextShown : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyDefaultQuotedTextShownEnabled] as? Bool else {
                //Default value
                return true
            }
            return value
        }
    }

    public var mdmAccountDefaultFolders : [String: String] {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyAccountDefaultFolders] as? [String: String] else {
                //Default value
                return [String:String]()
            }
            return value
        }
    }

    public var mdmRemoteSearchEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyRemoteSearchEnabled] as? Bool else {
                //Default value
                return true
            }
            return value
        }
    }

    public var mdmAccountRemoteSearchNumResults : Int {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyAccountRemoteSearchNumResults] as? Int else {
                //Default value
                return 50
            }
            return value
        }
    }

    public var mdmPEPSaveEncryptedOnServerEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyPEPSaveEncryptedOnServerEnabled] as? Bool else {
                //Default value
                return true
            }
            return value
        }
    }

    public var mdmPEPSyncAccountEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyPEPEnableSyncAccountEnabled] as? Bool else {
                //Default value
                return true
            }
            return value

        }
    }

    public var mdmPEPSyncNewDevicesEnabled : Bool {
        get {
            guard let dictionary = AppSettings.userDefaults.dictionary(forKey: MDMPredeployed.keyMDM),
                    let value = dictionary[AppSettings.keyPEPSyncNewDevicesEnabled] as? Bool else {
                //Default value
                return false
            }
            return value
        }
    }
}
