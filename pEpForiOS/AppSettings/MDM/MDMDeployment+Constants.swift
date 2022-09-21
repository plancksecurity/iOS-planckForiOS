//
//  MDMDeployment+Constants.swift
//  pEp
//
//  Created by Dirk Zimmermann on 29.08.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Constants, mainly for accessing MDM settings in user defaults.
extension MDMDeployment {
    /// The 'global' settings key under which all MDM settings are supposed to land.
    static let keyMDM = "com.apple.configuration.managed"

    /// The key for entry into composition settings.
    static let keyCompositionSettings = "composition_settings"

    /// The key for the account description, which an absence of a better name,
    /// may get used as the user's name.
    static let keyAccountDescription = "account_description"

    /// The top-level key into MDM-deployed account settings.
    static let keyAccountDeploymentMailSettings = "pep_mail_settings"

    /// The key into the MDM settings for an account's email address.
    static let keyUserAddress = "account_email_address"

    /// The MDM settings key for the incoming mail settings.
    static let keyIncomingMailSettings = "incoming_mail_settings"

    /// The MDM settings key for an incoming server address.
    static let keyIncomingMailSettingsServer = "incoming_mail_settings_server"

    /// The MDM settings key for the connection type for an incoming server.
    ///
    /// Can be one of NONE, SSL/TLS, STARTTLS. Any other value or not providing it will default to SSL/TLS.
    static let keyIncomingMailSettingsSecurityType = "incoming_mail_settings_security_type"

    /// The MDM settings key for the incoming mail server's port.
    static let keyIncomingMailSettingsPort = "incoming_mail_settings_port"

    /// The MDM settings key for the incoming mail server's _login_ name.
    static let keyIncomingMailSettingsUsername = "incoming_mail_settings_user_name"

    /// The MDM settings key for the outgoing mail settings.
    static let keyOutgoingMailSettings = "outgoing_mail_settings"

    /// The MDM settings key for an outgoing server address.
    static let keyOutgoingMailSettingsServer = "outgoing_mail_settings_server"

    /// The MDM settings key for the connection type for an outgoing server.
    ///
    /// Can be one of NONE, SSL/TLS, STARTTLS. Any other value or not providing it will default to STARTTLS.
    static let keyOutgoingMailSettingsSecurityType = "outgoing_mail_settings_security_type"

    /// The MDM settings key for the outgoing mail server's port.
    static let keyOutgoingMailSettingsPort = "outgoing_mail_settings_port"

    /// The MDM settings key for the outgoing mail server's _login_ name.
    static let keyOutgoingMailSettingsUsername = "outgoing_mail_settings_user_name"
}
