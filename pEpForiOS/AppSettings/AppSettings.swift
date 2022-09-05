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
    private var mdmSettingsObserver: NSKeyValueObservation?

    public func getAllUserDefaultValues() -> String {
        return AppSettings.userDefaults.dictionaryRepresentation().description
    }

    private init() {
        setup()
        registerForKeySyncDeviceGroupStateChangeNotification()
        registerForKeySyncDisabledByEngineNotification()
        startObserver()
    }

    private func startObserver() {
        mdmSettingsObserver = AppSettings.userDefaults.observe(\.mdmSettings, options: [.old, .new], changeHandler: { (defaults, change) in
            guard let newValue = change.newValue,
                  let oldValue = change.oldValue else {
                // Values not found
                return
            }

//            let name = Notification.Name.pEpMDMSettingsChanged
//            let info: [AnyHashable : Any] = [ "OldValue": oldValue, "NewValue": newValue ]
//            NotificationCenter.default.post(name:name, object: self, userInfo: info)
            let desc = "Old Value: \(String(describing: oldValue) ?? "-")\nNew Value: \(String(describing: newValue) ?? "-")"
            UIUtils.showAlertWithOnlyPositiveButton(title: "Llegó", message: desc)
        })
    }

    // MARK: - KeySyncStateProvider

    public var stateChangeHandler: ((Bool) -> Void)?

    public var isKeySyncEnabled: Bool {
        return keySyncEnabled
    }

    // MARK: - Deinit

    deinit {
        NotificationCenter.default.removeObserver(self)
        mdmSettingsObserver?.invalidate()
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
