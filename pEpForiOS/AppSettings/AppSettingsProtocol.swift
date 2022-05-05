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
    var keySyncEnabled: Bool { get set }
    var usePEPFolderEnabled: Bool { get set }
    var extraKeysEditable: Bool { get set }
    var unencryptedSubjectEnabled: Bool { get set }
    var threadedViewEnabled: Bool { get set }
    var passiveMode: Bool { get set }
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

    /// Banner error datetime
    ///
    /// Nil means it was never presented.
    var bannerErrorDate: Date? { get set }

    // MARK:- Collapsing State

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
