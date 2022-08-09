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

    static private var keyPEPEnablePrivacyProtectionEnabled = "keyPEPEnablePrivacyProtectionEnabled"
    static private var keyPEPExtraKeys = "keyPEPExtraKeys"
    static private var keyPEPTrustwordsEnabled = "keyPEPTrustwordsEnabled"
    static private var keyUnsecureDeliveryWarningEnabled = "keyUnsecureDeliveryWarningEnabled"
    static private var keyPEPSyncFolderEnabled = "keyPEPSyncFolderEnabled"
    static private var keyDebugLoggingEnabled = "keyDebugLoggingEnabled"
    static private var keyAccountDisplayCount = "keyAccountDisplayCount"
    static private var keyMaxPushFolders = "keyMaxPushFolders"
    static private var keyAccountDescription = "keyAccountDescription"
    static private var keyCompositionSenderName = "keyCompositionSenderName"
    static private var keyCompositionSignatureEnabled = "keyCompositionSignatureEnabled"
    static private var keyCompositionSignature = "keyCompositionSignature"
    static private var keyCompositionSignatureBeforeQuotedMessageEnabled = "keyCompositionSignatureBeforeQuotedMessageEnabled"
    static private var keyDefaultQuotedTextShownEnabled = "keyDefaultQuotedTextShownEnabled"
    static private var keyAccountDefaultFolders = "keyAccountDefaultFolders"
    static private var keyRemoteSearchEnabled = "keyRemoteSearchEnabled"
    static private var keyAccountRemoteSearchNumResults = "keyAccountRemoteSearchNumResults"
    static private var keyPEPSaveEncryptedOnServerEnabled = "keyPEPSaveEncryptedOnServerEnabled"
    static private var keyPEPEnableSyncAccountEnabled = "keyPEPEnableSyncAccountEnabled"
    static private var keyPEPSyncNewDevicesEnabled = "keyPEPSyncNewDevicesEnabled"
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

        // MARK: - MDM Defaults
        defaults[AppSettings.keyUnsecureDeliveryWarningEnabled] = true
        defaults[AppSettings.keyPEPSyncFolderEnabled] = true
        defaults[AppSettings.keyDebugLoggingEnabled] = false
        defaults[AppSettings.keyAccountDisplayCount] = 250
        defaults[AppSettings.keyCompositionSignatureEnabled] = true
        defaults[AppSettings.keyCompositionSignatureBeforeQuotedMessageEnabled] = false
        defaults[AppSettings.keyDefaultQuotedTextShownEnabled] = false
        defaults[AppSettings.keyAccountDefaultFolders] = []
        defaults[AppSettings.keyRemoteSearchEnabled] = true
        defaults[AppSettings.keyAccountRemoteSearchNumResults] = 50
        defaults[AppSettings.keyPEPSaveEncryptedOnServerEnabled] = true
        defaults[AppSettings.keyPEPEnableSyncAccountEnabled] = true
        defaults[AppSettings.keyPEPSyncNewDevicesEnabled] = false
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
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyPEPEnablePrivacyProtectionEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPEPEnablePrivacyProtectionEnabled)
        }
    }

    public var mdmPEPExtraKeys : [String] {
        get {
            return AppSettings.userDefaults.stringArray(forKey: AppSettings.keyPEPExtraKeys) ?? []
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPEPExtraKeys)
        }
    }

    public var mdmPEPTrustwordsEnabled : Bool {
        get {
            AppSettings.userDefaults.bool(forKey: AppSettings.keyPEPTrustwordsEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPEPTrustwordsEnabled)
        }
    }

    public var mdmUnsecureDeliveryWarningEnabled : Bool {
        get {
            AppSettings.userDefaults.bool(forKey: AppSettings.keyUnsecureDeliveryWarningEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyUnsecureDeliveryWarningEnabled)
        }
    }

    public var mdmPEPSyncFolderEnabled : Bool {
        get {
            AppSettings.userDefaults.bool(forKey: AppSettings.keyPEPSyncFolderEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPEPSyncFolderEnabled)
        }
    }

    public var mdmDebugLoggingEnabled : Bool {
        get {
            AppSettings.userDefaults.bool(forKey: AppSettings.keyDebugLoggingEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyDebugLoggingEnabled)
        }
    }

    public var mdmAccountDisplayCount: Int {
        get {
            AppSettings.userDefaults.integer(forKey: AppSettings.keyAccountDisplayCount)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyAccountDisplayCount)
        }
    }

    public var mdmMaxPushFolders : Int {
        get {
            AppSettings.userDefaults.integer(forKey: AppSettings.keyMaxPushFolders)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyMaxPushFolders)
        }
    }

    public var mdmAccountDescription : String? {
        get {
            return AppSettings.userDefaults.string(forKey: AppSettings.keyAccountDescription)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyAccountDescription)
        }
    }

    public var mdmCompositionSenderName : String? {
        get {
            return AppSettings.userDefaults.string(forKey: AppSettings.keyCompositionSenderName)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyCompositionSenderName)
        }
    }

    public var mdmCompositionSignatureEnabled : Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyCompositionSignatureEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyCompositionSignatureEnabled)
        }
    }
    public var mdmCompositionSignature : String? {
        get {
            return AppSettings.userDefaults.string(forKey: AppSettings.keyCompositionSignature)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyCompositionSignature)
        }
    }

    public var mdmCompositionSignatureBeforeQuotedMessage : String? {
        get {
            return AppSettings.userDefaults.string(forKey: AppSettings.keyCompositionSignatureBeforeQuotedMessageEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyCompositionSignatureBeforeQuotedMessageEnabled)
        }
    }

    public var mdmDefaultQuotedTextShown : Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyDefaultQuotedTextShownEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyDefaultQuotedTextShownEnabled)
        }
    }

    public var mdmAccountDefaultFolders : [String: String] {
        get {
            if let accountDefaultFolders = AppSettings.userDefaults.dictionary(forKey: AppSettings.keyAccountDefaultFolders) as? [String: String] {
                return accountDefaultFolders
            }
            return [String:String]()
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyAccountDefaultFolders)
        }
    }

    public var mdmRemoteSearchEnabled : Bool {
        get {
            return AppSettings.userDefaults.bool(forKey: AppSettings.keyRemoteSearchEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyRemoteSearchEnabled)
        }
    }

    public var mdmAccountRemoteSearchNumResults : Int {
        get {
            AppSettings.userDefaults.integer(forKey: AppSettings.keyAccountRemoteSearchNumResults)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyAccountRemoteSearchNumResults)
        }
    }

    public var mdmPEPSaveEncryptedOnServerEnabled : Bool {
        get {
            AppSettings.userDefaults.bool(forKey: AppSettings.keyPEPSaveEncryptedOnServerEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPEPSaveEncryptedOnServerEnabled)
        }
    }

    public var mdmPEPSyncAccountEnabled : Bool {
        get {
            AppSettings.userDefaults.bool(forKey: AppSettings.keyPEPEnableSyncAccountEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPEPEnableSyncAccountEnabled)
        }
    }

    public var mdmPEPSyncNewDevicesEnabled : Bool {
        get {
            AppSettings.userDefaults.bool(forKey: AppSettings.keyPEPSyncNewDevicesEnabled)
        }
        set {
            AppSettings.userDefaults.set(newValue, forKey: AppSettings.keyPEPSyncNewDevicesEnabled)
        }
    }
}
