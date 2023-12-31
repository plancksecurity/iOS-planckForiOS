//
//  MDMSettingsProtocol.swift
//  pEp
//
//  Created by Martín Brude on 30/8/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

/// Here we have a list of settings needed for the initial setup when using MDM:
/// https://confluence.pep.security/pages/viewpage.action?pageId=10223902
/// (see Settings meaning and structure)
///
/// Here we have the detail of the plist / json that is sent to the device:
/// https://confluence.pep.security/pages/viewpage.action?pageId=15008984
public protocol MDMSettingsProtocol {

    /// Indicate if the app is under MDM control.
    /// - Note: Even though this setting is part of MDM, it is handled differently than other
    /// MDM settings: It is _not_ actually coming from the MDM server, but part of the compile-time
    /// configuration.
    var mdmIsEnabled: Bool { get }

    /// Enable or disable pEp privacy protection for the user or device's account.
    var mdmPEPPrivacyProtectionEnabled: Bool { get }

    /// Provide Extra Keys.
    ///
    /// To remove them just set an empty array.
    var mdmPlanckExtraKeys: [[String:String]] { get }

    /// Enable or disable the use of trustwords.
    ///
    /// If disabled, it's impossible to invoke the trust management.
    var mdmPEPTrustwordsEnabled: Bool { get }

    /// Indicate if the Unsecure delivery warning is enabled
    ///
    /// When it's enabled, the unsecure Recipients in the
    /// "to", "cc", "bcc" fields from Message Compose screen will appear highlighted.
    /// Default is true.
    var mdmUnsecureDeliveryWarningEnabled: Bool { get }

    /// Indicate if a dedicated folder named is used to sync messages
    ///
    /// When enabled, it is used for pEp sync messages.
    /// When disabled, Inbox folder will be use for these messages instead.
    /// Default is true.
    var mdmPEPSyncFolderEnabled: Bool { get }

    /// Enable or disable the debug logging.
    ///
    /// When enabled, debug log will be displayed in a console.
    /// Default is false.
    var mdmDebugLoggingEnabled: Bool { get }

    /// Number of mails displayed in Email List view.
    ///
    /// The user can always fetch more mails from the server.
    /// Default is 250.
    var mdmAccountDisplayCount: Int { get }

    /// Max folders to check with push.
    var mdmMaxPushFolders: Int { get }

    /// Composition sender name
    ///
    /// If not provided or empty, email address will be used instead.
    var mdmCompositionSenderName: String? { get }

    /// Indicate if the signature should be used.
    ///
    /// Whether to include sender signature when composing emails.
    /// Default is true.
    var mdmCompositionSignatureEnabled: Bool { get }

    /// Signature to include in outgoing emails when mdmCompositionSignatureEnabled is enabled
    var mdmCompositionSignature: String? { get }

    /// Indicate whether to position the sender's signature before the quoted message in replies/forwards.
    ///
    /// Default is false.
    var mdmCompositionSignatureBeforeQuotedMessage: String? { get }

    /// Indicate whether to include quoted text in replied or forwarded mails
    ///
    /// Default is true.
    var mdmDefaultQuotedTextShown: Bool { get }

    /// Dictionary of folders names that the application will use for special purposes and their respective keys.
    ///
    /// By default all of them are empty.
    /// This means the app will try to find the relevant folders from the server.
    ///
    /// Folders keys are:
    /// - archive_folder: Folder where archived email are stored.
    /// - drafts_folder: Folder where mail drafts are stored.
    /// - sent_folder: Folder where sent mails are stored.
    /// - spam_folder: Folder where mails marked as spam are stored.
    /// - trash_folder: Folder where deleted mails are temporarily stored until they are permanently deleted.
    /// - The special value "-NONE-" can be entered to unassign a special folder.
    var mdmAccountDefaultFolders: [String: String] { get }

    /// When enabled the user can get more search results from the server.
    ///
    /// Default is true.
    var mdmRemoteSearchEnabled: Bool { get }

    /// Number of messages retrieved when a remote search is performed.
    ///
    /// Default is 50.
    var mdmAccountRemoteSearchNumResults: Int { get }

    /// Whether to enable the account to perform pEp sync.
    ///
    /// Default is true.
    var mdmPEPSaveEncryptedOnServerEnabled: Bool { get }

    /// Whether to enable the account to perform pEp sync.
    ///
    /// Default is true.
    var mdmPEPSyncAccountEnabled: Bool { get }

    /// Indicate if new devices can be added for an existing user identified by its email address.
    ///
    /// After the sync is done it should be set to false again.
    /// Default is false.
    var mdmPEPSyncNewDevicesEnabled: Bool { get }

    /// The list of media keys, which are dictionaries with three entries:
    ///  "media_key_address_pattern": The media key pattern
    ///  "media_key_fingerprint": The fingerprint of this media key
    ///  "media_key_material": The complete key material, in armored or comparable form.
    var mdmMediaKeys: [[String:String]] { get }

    /// Indicate if Echo Protocol is enabled.
    ///
    /// Echo allows the first message with content in an exchange to be protected.
    /// Default is true
    var mdmEchoProtocolEnabled: Bool { get }

    /// The OAuth Provider.
    /// It should be "GOOGLE" or "MICROSOFT".
    /// Default is MICROSOFT, so any other string will fall into MICROSOFT.
    var mdmAccountOauthProvider: String? { get }
}
