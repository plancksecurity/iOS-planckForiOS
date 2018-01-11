//
//  Account.swift
//  pEpForiOSUITests
//
//  Created by Dirk Zimmermann on 10.01.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

struct UIAccount {
    var nameOfTheUser: String
    var email: String
    var imapServerName: String
    var smtpServerName: String
    var password: String
    var imapPort: Int
    var smtpPort: Int

    /**
     This unfortunately must correspond to the localized name on screen.
     */
    var imapTransportSecurityString: String

    /**
     This unfortunately must correspond to the localized name on screen.
     */
    var smtpTransportSecurityString: String
}
