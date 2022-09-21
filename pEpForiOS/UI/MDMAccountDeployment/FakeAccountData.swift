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

        let compositionSettingsDict = [AppSettings.keyCompositionSenderName: "sender_name"]

        let imapSettingsDict: SettingsDict = [MDMDeployment.keyIncomingMailSettingsServer: "imap_server",
                                              MDMDeployment.keyIncomingMailSettingsSecurityType: "SSL/TLS",
                                              MDMDeployment.keyIncomingMailSettingsPort: NSNumber(value: 1993),
                                              MDMDeployment.keyIncomingMailSettingsUsername: loginname]

        let smtpSettingsDict: SettingsDict = [MDMDeployment.keyOutgoingMailSettingsServer: "smtp_server",
                                              MDMDeployment.keyOutgoingMailSettingsSecurityType: "STARTTLS",
                                              MDMDeployment.keyOutgoingMailSettingsPort: NSNumber(value: 1465),
                                              MDMDeployment.keyOutgoingMailSettingsUsername: loginname]

        let mailSettingsDict: SettingsDict = [MDMDeployment.keyUserAddress: "email@example.com",
                                              MDMDeployment.keyIncomingMailSettings: imapSettingsDict,
                                              MDMDeployment.keyOutgoingMailSettings: smtpSettingsDict]

        let mdmDict = [MDMDeployment.keyCompositionSettings: compositionSettingsDict,
                       MDMDeployment.keyAccountDeploymentMailSettings: mailSettingsDict]

        UserDefaults.standard.set(mdmDict, forKey: MDMDeployment.keyMDM)
    }
}
