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

// MARK: - AppSettings

/// Singleton representing and managing the App's settings.
public final class AppSettings: KeySyncStateProvider, AppSettingsProtocol {

    // MARK: - Singleton
    
    static public let shared = AppSettings()
    private var mdmDictionary: [String: Any] = [:]

    private init() {
        setup()
        registerForKeySyncDeviceGroupStateChangeNotification()
        registerForKeySyncDisabledByEngineNotification()
        startObserver()
    }

    public func startObserver() {
        if let values = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) {
            mdmDictionary = values
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDefaultsDidChange),
                                               name: UserDefaults.didChangeNotification,
                                               object: nil)
    }

    @objc private func userDefaultsDidChange(notification: NSNotification) {
        // We only care about standard user default settings, and specifically mdm settings
        guard let defaults = notification.object as? UserDefaults,
              defaults == UserDefaults.standard,
              let mdm = defaults.dictionary(forKey: MDMPredeployed.keyMDM) else {
            //Nothing to do
            return
        }

        // As ´Any´ does not conform to Equatable
        // we use NSDictionary to easily compare these dictionaries.
        let mdmSettingsHasChanged = !NSDictionary(dictionary: mdm).isEqual(to: mdmDictionary)
        if  mdmSettingsHasChanged {
            mdmDictionary = mdm
            NotificationCenter.default.post(name:.pEpMDMSettingsChanged, object: mdm, userInfo: nil)
        }
    }

    // MARK: - KeySyncStateProvider

    public var stateChangeHandler: ((Bool) -> Void)?

    public var isKeySyncEnabled: Bool {
        return keySyncEnabled
    }

    // MARK: - Deinit

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Private & Internal

extension AppSettings {

    static internal var userDefaults: UserDefaults = {
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
        MessageModelConfig.setPassiveModeEnabled(passiveModeEnabled)
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
}
