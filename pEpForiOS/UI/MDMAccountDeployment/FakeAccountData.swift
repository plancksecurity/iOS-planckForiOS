//
//  FakeAccountData.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.08.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

private typealias SettingsDict = [String:Any]

class FakeAccountData {
    func setupDeployableAccountData() {
        let loginname = "login_name"

        // Note: The use of hard-coded strings as settings keys is intentional.

        let compositionSettingsDict = [AppSettings.keyCompositionSenderName: "sender_name"]

        let imapSettingsDict: SettingsDict = ["incoming_mail_settings_server": "imap_server",
                                              "incoming_mail_settings_security_type": "SSL/TLS",
                                              "incoming_mail_settings_port": NSNumber(value: 1993),
                                              "incoming_mail_settings_user_name": loginname]

        let smtpSettingsDict: SettingsDict = ["outgoing_mail_settings_server": "smtp_server",
                                              "outgoing_mail_settings_security_type": "STARTTLS",
                                              "outgoing_mail_settings_port": NSNumber(value: 1465),
                                              "outgoing_mail_settings_user_name": loginname]

        let mailSettingsDict: SettingsDict = ["account_email_address": "email@example.com",
                                              "incoming_mail_settings": imapSettingsDict,
                                              "outgoing_mail_settings": smtpSettingsDict]

        let mdmDict = ["composition_settings": compositionSettingsDict,
                       "pep_mail_settings": mailSettingsDict]

        UserDefaults.standard.set(mdmDict, forKey: MDMDeployment.keyMDM)
    }
}
