//
//  AppSettingsProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 27.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

public protocol AppSettingsProtocol {
    /// Indicates if keySync is enabled
    var keySyncEnabled: Bool { get set }

    /// Indicates if the PEP folder is enabled
    var usePEPFolderEnabled: Bool { get set }

    /// Indicates if the extra keys are editable.
    var extraKeysEditable: Bool { get set }

    /// Indicates if the unencryped subject is enabled.
    var unencryptedSubjectEnabled: Bool { get set }

    var threadedViewEnabled: Bool { get set }

    /// Indicates if Passive mode is on.
    var passiveMode: Bool { get set }

    /// The email address of the default account.
    var defaultAccount: String? { get set }

    var lastKnownDeviceGroupState: DeviceGroupState { get set }

    var shouldShowTutorialWizard: Bool { get set }
    /// Whether or not the user has already answered the "Do you want to allow pEp app to access 
    /// your contacts"
    var userHasBeenAskedForContactAccessPermissions: Bool { get set }
    /// Whether or not to warn the user in case a forwarded message is less secure as the forwarded
    /// (original) message.
    var unsecureReplyWarningEnabled: Bool { get set }

    /// Should the logging be verbose, or not?
    var verboseLogginEnabled : Bool { get set }

    /// The list of the accepted languages codes for truswords. 
    var acceptedLanguagesCodes : [String] { get set }

    // MARK: - MDM

    /// Here we have a list of settings needed for the initial setup when using MDM.
    /// https://confluence.pep.security/pages/viewpage.action?pageId=10223902 (see Settings meaning and structure)

    /// Enable or disable pEp privacy protection for the user or device's account.
    var mdmPEPEnablePrivacyProtection: Bool { get set }

    /// Extra keys can be provided using this setting
    /// extra keys can be removed if the setting is provided and all fingerprint elements are blank.
    /// So the lack of extra keys willl be an empty array.
    var mdmPEPExtraKeys: [String] { get set }

    /// This is an advanced feature.
    /// It allows using a handshake method to establish trust between two users.
    var mdmPEPUseTrustwords: Bool { get set }

    /// When this setting is enabled, the unsecure Recipients in the "to", "cc", "bcc" fields from Message Compose screen
    ///  will appear highlighted in red color.
    /// Default is true.
    var mdmUnsecureDeliveryWarning: Bool { get set }

    /// This is an advanced feature.
    /// When enabled, a dedicated pEp folder is used for pEp sync messages.
    /// When disabled, Inbox folder will be user for these messages instead.
    /// Default is true.
    var mdmPEPSyncFolder: Bool { get set }

    /// This is an advanced feature. When enabled, debug log can be displayed in a console.
    /// Default is false.
    var mdmDebugLogging: Bool { get set }

    /// Number of mails displayed in Message List screen by default.
    /// The user can always refresh more mails from the server.
    /// Configuration designers like Intune's one are handy for this setting
    /// Default is 250.
    var mdmAccountDisplayCount: Int { get set }

    /// Max folders to check with push. Advanced setting
    var mdmMaxPushFolders: Int { get set }

    /// Defaults to MDM's {{username}}.
    /// If not provided or empty, email address will be used instead.
    /// Name that will be displayed in several places of the app, associated with the user account.
    /// Setting this value is optional for deployment.
    var mdmAccountDescription: String? { get set }

    /// Defaults to MDM's {{username}}, recommended for deployment.
    /// If not provided or empty, email address will be used instead.
    var mdmCompositionSenderName: String? { get set }

    /// Whether to include sender signature when composing emails.
    /// Default is true.
    var mdmCompositionUseSignature: String? { get set }

    /// Signature to include in outgoing emails when composition_use_signature is enabled
    var mdmCompositionSignature: String? { get set }

    /// Whether to position the sender's signature before the quoted message in replies/forwards.
    /// (Signature after quoted message by default).
    /// Default is false.
    var mdmCompositionSignatureBeforeQuotedMessage: String? { get set }

    /// Whether to position sender signature before the quoted message in replies/forwards.
    /// (Signature after quoted message by default).
    /// Default is false.
    var mdmDefaultQuotedTextShown: String? { get set }

    /// Folders that the application will use as special archive, drafts, sent, spam, trash folders.
    /// By default all of them are empty.
    /// This means the app will try to find the relevant folders from the server.
    /// Removing folder elements from JSON has the same effect in this case.
    ///
    /// Folders keys are:
    /// - archive_folder: Folder where archived email are stored.
    /// - drafts_folder: Folder where mail drafts are stored.
    /// - sent_folder: Folder where sent mails are stored.
    /// - spam_folder: Folder where mails marked as spam are stored.
    /// - trash_folder: Folder where deleted mails are temporarily stored until they are permanently deleted.
    /// - The special value "-NONE-" can be entered to unassign a special folder.
    var mdmAccountDefaultFolders: [String]? { get set }

    /// When enabled, a button for remote search will appear in local search screen,
    /// so that the user can get more search results from the server.
    /// Default is true.
    var mdmRemoteSearchEnabled: Bool { get set }

    /// Number of messages retrieved when a remote search is performed.
    /// Default is 50.
    var mdmAccountRemoteSearchNumResults: Int { get set }

    /// This is an advanced feature. Whether to enable the account to perform pEp sync.
    /// Default is true.
    var mdmPEPSaveEncryptedOnServer: Bool { get set }

    /// This is an advanced feature. Whether to enable the account to perform pEp sync.
    /// Default is true.
    var mdmPEPEnableSyncAccount: Bool { get set }

    /// This setting can be enabled from MDM to allow to add new devices for an existing user (mail address).
    /// After the sync is done it should be set to false again.
    /// Default is false.
    var mdmAllowPEPSyncNewDevices: Bool { get set }

    // MARK: - Collapsing State

    /// Removes the collapsing state for the account address passed by parameter.
    /// - Parameter address: The address of the account to delete its collapsing states preferences.
    func removeFolderViewCollapsedStateOfAccountWith(address: String)

    /// Retrieves the collapsed state for the account passed by parameter.
    ///
    /// - Parameter address: The account address to check its collapsed state
    /// - returns: True if it is collapsed, false if not, or if not found, as it means that hasn't been collapsed yet.
    func folderViewCollapsedState(forAccountWith address: String) -> Bool

    /// Retrieves the collapsed state for the folder passed by parameter in the account passed by parameter.
    ///
    /// - Parameter address: The account to check its collapsed state
    ///   - folderName: The name of the folder. For example: `Inbox.My Folder`
    ///   - address: The account address to check the collapsed state of its folder.
    /// - Returns: True if it is collapsed, false if not, or if not found, as it means that hasn't been collapsed yet.
    func folderViewCollapsedState(forFolderNamed folderName: String, ofAccountWith address: String) -> Bool

    /// Set changes in the collapsing state of the folder passed by parameter
    ///
    /// - Parameters:
    ///   - address: The account address
    ///   - folderName: The name of the folder. For example: `Inbox.My Folder`
    ///   - isCollapsed: The collapsing state.
    func setFolderViewCollapsedState(forFolderNamed folderName: String, ofAccountWith address: String, to value: Bool)

    /// Set changes in the collapsing state of the account passed by parameter
    ///
    /// - Parameters:
    ///   - address: The account address
    ///   - isCollapsed: The collapsing state.
    func setFolderViewCollapsedState(forAccountWith address: String, to value: Bool)
}
