//
//  MDMAppSettingsProtocol.swift
//  pEp
//
//  Created by Martín Brude on 9/8/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

/// Here we have a list of settings needed for the initial setup when using MDM.
/// https://confluence.pep.security/pages/viewpage.action?pageId=10223902 (see Settings meaning and structure)
public protocol MDMAppSettingsProtocol {

    /// Indicate if the app has been deployed via MDM.
    /// - Note: Even though this setting is part of MDM, it is handled differently than other
    /// MDM settings: It is _not_ actuallly coming from the MDM server, but part of the book-keeping
    /// in the app about MDM. In other words, it is MDM-related, but handled by the app similar to other
    /// settings.
    var hasBeenMDMDeployed: Bool { get }

    /// Enable or disable pEp privacy protection for the user or device's account.
    var mdmPEPPrivacyProtectionEnabled: Bool { get }

    /// Provide Extra Keys.
    ///
    /// To remove them just set an empty array. 
    var mdmPEPExtraKeys: [String] { get }

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
}
