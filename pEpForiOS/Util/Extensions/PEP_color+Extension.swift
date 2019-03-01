//
//  PEPColor+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension PEPColor {
    var privacyStatusTitle: String {
        switch self {
        case PEPColor_red:
            return NSLocalizedString("Mistrusted", comment: "privacyStatusTitle red")
        case PEPColor_yellow:
            return NSLocalizedString("Secure", comment: "privacyStatusTitle yellow")
        case PEPColor_green:
            return NSLocalizedString("Secure & Trusted", comment: "privacyStatusTitle green")
        case PEPColor_no_color:
            return NSLocalizedString("None", comment: "privacyStatusTitle no_color")
        default:
            return "Undefined"
        }
    }

    var privacyStatusDescription: String {
        switch self {
        case PEPColor_red:
            return NSLocalizedString("This communication partner is mistrusted",
                                     comment: "privacyStatusDescription red")
        case PEPColor_yellow:
            return NSLocalizedString(
                "Make this communication partner secure & trusted by comparing the trustwords below with your partner, for example by making a phone call",
                comment: "privacyStatusDescription yellow")
        case PEPColor_green:
            return NSLocalizedString(
                "This communication partner is secure and trusted",
                comment: "privacyStatusDescription green")
        case PEPColor_no_color:
            return NSLocalizedString("None", comment: "privacyStatusDescription no_color")
        default:
            return "Undefined"
        }
    }
}
