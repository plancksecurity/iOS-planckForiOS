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

    var email: String
    var username: String
    var password: String

    var serverhostIMAP:String
    var portIMAP:String
    var transportSecurityIMAP:String

    var serverhostSMTP:String
    var portSMTP:String
    var transportSecuritySMTP:String

    init(email:String, username:String, password:String,
         serverhostIMAP:String, portIMAP:String, transportSecurityIMAP:String,
         serverhostSMTP:String, portSMTP:String, transportSecuritySMTP:String) {

        self.email = email
        self.username = username
        self.password = password

        self.serverhostIMAP = serverhostIMAP
        self.portIMAP = portIMAP
        self.transportSecurityIMAP = transportSecurityIMAP

        self.serverhostSMTP = serverhostSMTP
        self.portSMTP = portSMTP
        self.transportSecuritySMTP = transportSecuritySMTP
    }
}

