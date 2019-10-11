//
//  PEPColor+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework

extension PEPColor {
    var privacyStatusTitle: String {
        switch self {
        case PEPColor.red:
            return NSLocalizedString("Mistrusted", comment: "privacyStatusTitle red")
        case .yellow:
            return NSLocalizedString("Secure", comment: "privacyStatusTitle yellow")
        case .green:
            return NSLocalizedString("Secure & Trusted", comment: "privacyStatusTitle green")
        case PEPColor.noColor:
            return NSLocalizedString("None", comment: "privacyStatusTitle no_color")
        default:
            return "Undefined"
        }
    }

    var privacyStatusDescription: String {
        switch self {
        case PEPColor.red:
            return NSLocalizedString("This contact is mistrusted and might be an attack by a man-in-the-middle.",
                                     comment: "privacyStatusDescription red")
        case .yellow:
            return NSLocalizedString(
                "Communication with this contact will be completely Secure & Trusted by comparing the following Trustwords with your contact, for example by making a phone call.",
                comment: "privacyStatusDescription yellow")
        case .green:
            return NSLocalizedString(
                "This contact is completely trusted. All communication will be with the maximum level of privacy.",
                comment: "privacyStatusDescription green")
        case PEPColor.noColor:
            return NSLocalizedString("Unknown", comment: "privacyStatusDescription no_color")
        default:
            return "Undefined"
        }
    }
}
