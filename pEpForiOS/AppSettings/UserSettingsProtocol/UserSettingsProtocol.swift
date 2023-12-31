//
//  UserAppSettingsProtocol.swift
//  pEp
//
//  Created by Martín Brude on 30/8/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

public protocol UserSettingsProtocol {

    /// Indicates if planck sync activity indicator should run
    var keyPlanckSyncActivityIndicatorIsOn: Bool { get set }

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
