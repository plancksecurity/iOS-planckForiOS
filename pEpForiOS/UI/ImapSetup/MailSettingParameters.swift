//
//  MailSettingParameters.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class MailSettingParameters {

    var email: String?
    var username: String?
    var password: String?

    var serverhostIMAP:String?
    var portIMAP:UInt16?
    var transportSecurityIMAP:ConnectionTransport?

    var serverhostSMTP:String?
    var portSMTP:UInt16?
    var transportSecuritySMTP:ConnectionTransport?

}

