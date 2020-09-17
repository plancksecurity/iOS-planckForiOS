//
//  AppSettings.swift
//  pEp
//
//  Created by Dirk Zimmermann on 27.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

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
}

// MARK: - AppSettings

/// Signleton representing and managing the App's settings.
public final class AppSettings: KeySyncStateProvider {

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

    static private let appGroupId = "group.security.pep.pep4ios"
    static private var userDefaults: UserDefaults = {
        guard let appGroupDefaults = UserDefaults.init(suiteName: appGroupId) else {
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
}
