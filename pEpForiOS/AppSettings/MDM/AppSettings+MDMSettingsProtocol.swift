//
//  AppSettings+MDMSettingsProtocol.swift
//  pEp
//
//  Created by Martín Brude on 30/8/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension AppSettings: MDMSettingsProtocol {

    // MARK: - Keys

    static let keyPEPEnablePrivacyProtectionEnabled = "pep_enable_privacy_protection"
    static let keyPEPExtraKeys = "pep_extra_keys"
    static let keyPEPTrustwordsEnabled = "pep_use_trustwords"
    static let keyUnsecureDeliveryWarningEnabled = "unsecure_delivery_warning"
    static let keyPEPSyncFolderEnabled = "pep_sync_folder"
    static let keyCompositionSenderName = "composition_sender_name"

    static let keyCompositionSignatureEnabled = "composition_use_signature"
    static let keyCompositionSignature = "composition_signature"
    static let keyCompositionSignatureBeforeQuotedMessageEnabled = "composition_signature_before_quoted_message"
    static let keyDefaultQuotedTextShownEnabled = "default_quoted_text_shown"
    static let keyAccountDefaultFolders = "account_default_folders"
    static let keyRemoteSearchEnabled = "remote_search_enabled"
    static let keyAccountRemoteSearchNumResults = "account_remote_search_num_results"
    static let keyPEPSaveEncryptedOnServerEnabled = "pep_save_encrypted_on_server"
    static let keyPEPEnableSyncAccountEnabled = "pep_enable_sync_account"
    static let keyPEPSyncNewDevicesEnabled = "allow_pep_sync_new_devices"
    static let keyMediaKeys = "pep_media_keys"
    static let keyEchoProtocolEnabled = "pep_enable_echo_protocol"

    static let keyAuditLoggingMaxFileTime = "auditLoggingMaxFileTime"

    //Not used
    static let keyDebugLoggingEnabled = "debug_logging"
    static let keyAccountDisplayCount = "account_display_count"
    static let keyMaxPushFolders = "max_push_folders"

    // MARK: - Settings

    public var mdmIsEnabled: Bool {
        get {
            return MDMUtil.isEnabled()
        }
    }
    
    public var mdmAuditLoggingMaxFileTime: Int {
        get {
            guard let auditLoggingMaxFileTime = mdmDictionary[AppSettings.keyAuditLoggingMaxFileTime] as? Int else {
                return 30
            }
            return auditLoggingMaxFileTime
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

    public var mdmPEPExtraKeys: [[String:String]] {
        get {
            guard let extraKeys = mdmDictionary[AppSettings.keyPEPExtraKeys] as? [[String:String]] else {
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

    public var mdmMediaKeys: [[String:String]] {
        get {
            guard let mediaKeys = mdmDictionary[AppSettings.keyMediaKeys] as? [[String:String]] else {
                return []
            }

            return mediaKeys
        }
    }

    public var mdmEchoProtocolEnabled: Bool {
        get {
            guard let isEchoProtocolEnabled = mdmDictionary[AppSettings.keyEchoProtocolEnabled] as? Bool else {
                // Default value from documentation
                return true
            }
            return isEchoProtocolEnabled
        }
    }

    // MARK: - Private

    private var mdmDictionary: [String: Any] {
        // MDM dictionary goes to the standard UserDefaults, not our instance.
        guard let dictionary = UserDefaults.standard.dictionary(forKey: MDMDeployment.keyMDM) else {
            return [String: Any]()
        }
        return dictionary
    }
}
