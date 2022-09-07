//
//  AppSettings+MDMSettingsProtocol.swift
//  pEp
//
//  Created by Martín Brude on 30/8/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

extension AppSettings: MDMSettingsProtocol {

    // MARK: - Keys

    static internal let keyhasBeenMDMDeployed = "keyhasBeenMDMDeployed"
    static internal var keyPEPEnablePrivacyProtectionEnabled = "pep_enable_privacy_protection"
    static internal var keyPEPExtraKeys = "pep_extra_keys"
    static internal var keyPEPTrustwordsEnabled = "pep_use_trustwords"
    static internal var keyUnsecureDeliveryWarningEnabled = "unsecure_delivery_warning"
    static internal var keyPEPSyncFolderEnabled = "pep_sync_folder"
    static internal var keyDebugLoggingEnabled = "debug_logging"
    static internal var keyAccountDisplayCount = "account_display_count"
    static internal var keyMaxPushFolders = "max_push_folders"
    static internal var keyCompositionSenderName = "composition_sender_name"
    static internal var keyCompositionSignatureEnabled = "composition_use_signature"
    static internal var keyCompositionSignature = "composition_signature"
    static internal var keyCompositionSignatureBeforeQuotedMessageEnabled = "composition_signature_before_quoted_message"
    static internal var keyDefaultQuotedTextShownEnabled = "default_quoted_text_shown"
    static internal var keyAccountDefaultFolders = "account_default_folders"
    static internal var keyRemoteSearchEnabled = "remote_search_enabled"
    static internal var keyAccountRemoteSearchNumResults = "account_remote_search_num_results"
    static internal var keyPEPSaveEncryptedOnServerEnabled = "pep_save_encrypted_on_server"
    static internal var keyPEPEnableSyncAccountEnabled = "pep_enable_sync_account"
    static internal var keyPEPSyncNewDevicesEnabled = "allow_pep_sync_new_devices"

    // MARK: - Settings

    public var hasBeenMDMDeployed: Bool {
        get {
            guard let hasBeenMDMDeployed = mdmDictionary[AppSettings.keyhasBeenMDMDeployed] as? Bool else {
                return false
            }
            return hasBeenMDMDeployed
        }
    }

    public var mdmPEPPrivacyProtectionEnabled: Bool {
        get {
            guard let isPrivacyProtectionEnabled = mdmDictionary[AppSettings.keyPEPEnablePrivacyProtectionEnabled] as? Bool else {
                return false
            }
            return isPrivacyProtectionEnabled
        }
    }

    public var mdmPEPExtraKeys: [String] {
        get {
            guard let extraKeys = mdmDictionary[AppSettings.keyPEPExtraKeys] as? [String] else {
                return []
            }
            return extraKeys
        }
    }

    public var mdmPEPTrustwordsEnabled: Bool {
        get {
            guard let isTrustManagementEnabled = mdmDictionary[AppSettings.keyPEPTrustwordsEnabled] as? Bool else {
                return false
            }
            return isTrustManagementEnabled
        }
    }

    public var mdmUnsecureDeliveryWarningEnabled: Bool {
        get {
            guard let isUnsecureDeliveryWarningEnabled = mdmDictionary[AppSettings.keyUnsecureDeliveryWarningEnabled] as? Bool else {
                return true
            }
            return isUnsecureDeliveryWarningEnabled
        }
    }

    public var mdmPEPSyncFolderEnabled: Bool {
        get {
            guard let isSyncFolderEnabled = mdmDictionary[AppSettings.keyPEPSyncFolderEnabled] as? Bool else {
                return false
            }
            return isSyncFolderEnabled
        }
    }

    public var mdmDebugLoggingEnabled: Bool {
        get {
            guard let isDebugLogginEnabled = mdmDictionary[AppSettings.keyDebugLoggingEnabled] as? Bool else {
                //Default value from documentation
                return false
            }
            return isDebugLogginEnabled
        }
    }

    public var mdmAccountDisplayCount: Int {
        get {
            guard let accountDisplayCount = mdmDictionary[AppSettings.keyAccountDisplayCount] as? Int else {
                //Default value from documentation
                return 250
            }
            return accountDisplayCount
        }
    }

    public var mdmMaxPushFolders: Int {
        get {
            guard let maxPushFolder = mdmDictionary[AppSettings.keyMaxPushFolders] as? Int else {
                //Default value from documentation
                return 0
            }
            return maxPushFolder
        }
    }

    public var mdmCompositionSenderName: String? {
        get {
            guard let senderName = mdmDictionary[AppSettings.keyCompositionSenderName] as? String else {
                return nil
            }
            return senderName
        }
    }

    public var mdmCompositionSignatureEnabled: Bool {
        get {
            guard let isSignatureEnabled = mdmDictionary[AppSettings.keyCompositionSignatureEnabled] as? Bool else {
                //Default value
                return true
            }
            return isSignatureEnabled
        }
    }

    public var mdmCompositionSignature: String? {
        get {
            guard let signature = mdmDictionary[AppSettings.keyCompositionSignature] as? String else {
                return nil
            }
            return signature
        }
    }

    public var mdmCompositionSignatureBeforeQuotedMessage: String? {
        get {
            guard let compositionSignatureBeforeQuotedMessage = mdmDictionary[AppSettings.keyCompositionSignatureBeforeQuotedMessageEnabled] as? String else {
                return nil
            }
            return compositionSignatureBeforeQuotedMessage
        }
    }

    public var mdmDefaultQuotedTextShown: Bool {
        get {
            guard let isDefaultQuotedTextShown = mdmDictionary[AppSettings.keyDefaultQuotedTextShownEnabled] as? Bool else {
                // Default value from documentation
                return true
            }
            return isDefaultQuotedTextShown
        }
    }

    public var mdmAccountDefaultFolders: [String: String] {
        get {
            guard let folders = mdmDictionary[AppSettings.keyAccountDefaultFolders] as? [String: String] else {
                // Default value from documentation
                return [String:String]()
            }
            return folders
        }
    }

    public var mdmRemoteSearchEnabled: Bool {
        get {
            guard let isRemoteSearchEnabled = mdmDictionary[AppSettings.keyRemoteSearchEnabled] as? Bool else {
                // Default value from documentation
                return true
            }
            return isRemoteSearchEnabled
        }
    }

    public var mdmAccountRemoteSearchNumResults: Int {
        get {
            guard let numberOfRemoteSearchResults = mdmDictionary[AppSettings.keyAccountRemoteSearchNumResults] as? Int else {
                // Default value from documentation
                return 50
            }
            return numberOfRemoteSearchResults
        }
    }

    public var mdmPEPSaveEncryptedOnServerEnabled: Bool {
        get {
            guard let isSaveEncryptedOnServerEnabled = mdmDictionary[AppSettings.keyPEPSaveEncryptedOnServerEnabled] as? Bool else {
                // Default value from documentation
                return true
            }
            return isSaveEncryptedOnServerEnabled
        }
    }

    public var mdmPEPSyncAccountEnabled: Bool {
        get {
            guard let isSyncEnabled = mdmDictionary[AppSettings.keyPEPEnableSyncAccountEnabled] as? Bool else {
                // Default value from documentation
                return true
            }
            return isSyncEnabled
        }
    }

    public var mdmPEPSyncNewDevicesEnabled: Bool {
        get {
            guard let isSyncNewDevicesEnabled = mdmDictionary[AppSettings.keyPEPSyncNewDevicesEnabled] as? Bool else {
                // Default value from documentation
                return false
            }
            return isSyncNewDevicesEnabled
        }
    }

    // MARK: - Private

    private var mdmDictionary: [String: Any?] {
        // MDM dictionary goes to the standard UserDefaults, not our instance.
        guard let dictionary = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) else {
            return [String: Any?]()
        }
        return dictionary
    }
}
