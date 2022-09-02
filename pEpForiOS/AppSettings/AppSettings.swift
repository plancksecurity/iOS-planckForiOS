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

extension UserDefaults {

    @objc dynamic var keyhasBeenMDMDeployed: Bool {
        return bool(forKey: "keyhasBeenMDMDeployed")
    }

    @objc dynamic var keyPEPEnablePrivacyProtectionEnabled: Bool {
        return bool(forKey: "pep_enable_privacy_protection")
    }

    @objc dynamic var keyPEPTrustwordsEnabled: Bool {
        return bool(forKey: "pep_use_trustwords")
    }

    @objc dynamic var keyUnsecureDeliveryWarningEnabled: Bool {
        return bool(forKey: "unsecure_delivery_warning")
    }

    @objc dynamic var keyPEPSaveEncryptedOnServerEnabled: Bool {
        return bool(forKey: "pep_save_encrypted_on_server")
    }

    @objc dynamic var keyPEPEnableSyncAccountEnabled: Bool {
        return bool(forKey: "pep_enable_sync_account")
    }

    @objc dynamic var keyPEPSyncNewDevicesEnabled: Bool {
        return bool(forKey: "allow_pep_sync_new_devices")
    }

    @objc dynamic var keyRemoteSearchEnabled: Bool {
        return bool(forKey: "remote_search_enabled")
    }

    @objc dynamic var keyDefaultQuotedTextShownEnabled: Bool {
        return bool(forKey: "default_quoted_text_shown")
    }

    @objc dynamic var keyCompositionSignatureBeforeQuotedMessageEnabled: Bool {
        return bool(forKey: "composition_signature_before_quoted_message")
    }

    @objc dynamic var keyCompositionSignatureEnabled: Bool {
        return bool(forKey: "composition_use_signature")
    }

    @objc dynamic var keyPEPSyncFolderEnabled: Bool {
        return bool(forKey: "pep_sync_folder")
    }

    @objc dynamic var keyDebugLoggingEnabled: Bool {
        return bool(forKey: "debug_logging")
    }

    @objc dynamic var keyPEPExtraKeys: [String] {
        if let extraKeys = array(forKey: "pep_extra_keys") as? [String] {
            return extraKeys
        }
        return [String]()
    }

//    static private var keyPEPExtraKeys = "pep_extra_keys"
//    static private var keyAccountDisplayCount = "account_display_count"
//    static private var keyMaxPushFolders = "max_push_folders"
//    static private var keyCompositionSenderName = "composition_sender_name"
//    static private var keyCompositionSignature = "composition_signature"
//    static private var keyAccountDefaultFolders = "account_default_folders"
//    static private var keyAccountRemoteSearchNumResults = "account_remote_search_num_results"

}

// MARK: - AppSettings

/// Singleton representing and managing the App's settings.
public final class AppSettings: KeySyncStateProvider, AppSettingsProtocol {

    // MARK: - Singleton
    
    static public let shared = AppSettings()
    var observer: NSKeyValueObservation?
    var observers: [NSKeyValueObservation] = []

    private init() {
        setup()
        registerForKeySyncDeviceGroupStateChangeNotification()
        registerForKeySyncDisabledByEngineNotification()
        startObserver()
    }

//    static func getAllKeyPaths() -> [WritableKeyPath<AppSettings, Bool>] {
//        let a:[WritableKeyPath<UserDefaults, Bool>] = [
//            \.AppSettings.userDefaults.keyhasBeenMDMDeployed,
//             \.AppSettings.userDefaults.keyPassiveMode,
//             \.AppSettings.userDefaults.keyPEPEnablePrivacyProtectionEnabled,
//             \AppSettings.userDefaults.keyPEPTrustwordsEnabled,
//             \AppSettings.userDefaults.keyUnsecureDeliveryWarningEnabled
//        ]
//
//        return a
//    }
//
//             @objc dynamic var keyUnsecureDeliveryWarningEnabled: Bool {
//                 return bool(forKey: "unsecure_delivery_warning")
//             }
//
//             @objc dynamic var keyPEPSaveEncryptedOnServerEnabled: Bool {
//                 return bool(forKey: "pep_save_encrypted_on_server")
//             }
//
//             @objc dynamic var keyPEPEnableSyncAccountEnabled: Bool {
//                 return bool(forKey: "pep_enable_sync_account")
//             }
//
//             @objc dynamic var keyPEPSyncNewDevicesEnabled: Bool {
//                 return bool(forKey: "allow_pep_sync_new_devices")
//             }
//
//             @objc dynamic var keyRemoteSearchEnabled: Bool {
//                 return bool(forKey: "remote_search_enabled")
//             }
//
//             @objc dynamic var keyDefaultQuotedTextShownEnabled: Bool {
//                 return bool(forKey: "default_quoted_text_shown")
//             }
//
//             @objc dynamic var keyCompositionSignatureBeforeQuotedMessageEnabled: Bool {
//                 return bool(forKey: "composition_signature_before_quoted_message")
//             }
//
//             @objc dynamic var keyCompositionSignatureEnabled: Bool {
//                 return bool(forKey: "composition_use_signature")
//             }
//
//             @objc dynamic var keyPEPSyncFolderEnabled: Bool {
//                 return bool(forKey: "pep_sync_folder")
//             }
//
//             @objc dynamic var keyDebugLoggingEnabled: Bool {
//                 return bool(forKey: "debug_logging")

//    }

    private func startObserver() {
        let observer = AppSettings.userDefaults.observe(\.keyhasBeenMDMDeployed, options: [.old, .new], changeHandler: { (defaults, change) in
            guard let newValue = change.newValue,
                  let oldValue = change.oldValue else {
                // Values not found
                return
            }
            let name = Notification.Name.pEpMDMSettingsChanged
            let info = [ "OldValue": oldValue, "NewValue": newValue ]
            NotificationCenter.default.post(name:name, object: self, userInfo: info)
        })

        observers.append(observer)
    }

    // MARK: - KeySyncStateProvider

    public var stateChangeHandler: ((Bool) -> Void)?

    public var isKeySyncEnabled: Bool {
        return keySyncEnabled
    }

    // MARK: - Deinit

    deinit {
        NotificationCenter.default.removeObserver(self)
        observers.forEach { observer in
            observer.invalidate()
        }

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
