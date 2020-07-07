//
//  AppSettingsProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 27.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

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
}
