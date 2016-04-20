//
//  MailSettingParameters.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit




class MailSettingParameters {

    enum transportSecurity {
        case None,TLS,StartTLS
    }

    var email: String?
    var username: String?
    var password: String?

    var serverhostIMAP:String?
    var portIMAP:String?
    var transportSecurityIMAP:String?

    var serverhostSMTP:String?
    var portSMTP:String?
    var transportSecuritySMTP:String?
}

