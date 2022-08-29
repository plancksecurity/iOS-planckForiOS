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

    /// Indicates if Passive mode is enabled.
    var passiveModeEnabled: Bool { get set }

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
    var verboseLogginEnabled: Bool { get set }

    /// The list of the accepted languages codes for truswords. 
    var acceptedLanguagesCodes: [String] { get set }

    // MARK: - MDM

    /// Indicate if the app has been deployed via MDM
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
