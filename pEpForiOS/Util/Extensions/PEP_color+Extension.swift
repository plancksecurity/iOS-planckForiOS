//
//  PEP_color+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension PEP_color {
    var privacyStatusTitle: String {
        switch self {
        case PEP_color_red:
            return NSLocalizedString("Mistrusted", comment: "privacyStatusTitle red")
        case PEP_color_yellow:
            return NSLocalizedString("Secure", comment: "privacyStatusTitle yellow")
        case PEP_color_green:
            return NSLocalizedString("Secure & Trusted", comment: "privacyStatusTitle green")
        case PEP_color_no_color:
            return NSLocalizedString("None", comment: "privacyStatusTitle no_color")
        default:
            return "Undefined"
        }
    }

    var privacyStatusDescription: String {
        switch self {
        case PEP_color_red:
            return NSLocalizedString("This communication partner is mistrusted",
                                     comment: "privacyStatusDescription red")
        case PEP_color_yellow:
            return NSLocalizedString(
                "Make this communication partner secure & trusted by comparing the trustwords below with your partner, for example by making a phone call",
                comment: "privacyStatusDescription yellow")
        case PEP_color_green:
            return NSLocalizedString(
                "This communication partner is secure and trusted",
                comment: "privacyStatusDescription green")
        case PEP_color_no_color:
            return NSLocalizedString("None", comment: "privacyStatusDescription no_color")
        default:
            return "Undefined"
        }
    }
}
