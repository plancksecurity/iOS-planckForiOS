//
//  Color+PrivacyStatusDescription.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.08.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

extension Color {
    var privacyStatusDescription: String {
        switch self {
        case .red:
            return NSLocalizedString("This contact is mistrusted and might be an attack by a man-in-the-middle.",
                                     comment: "privacyStatusDescription red")
        case .yellow:
            return NSLocalizedString(
                "Communication with this contact will be completely verified by comparing the following Trustwords/Fingerprints with your contact, for example by making a phone call.",
                comment: "privacyStatusDescription yellow")
        case .green:
            return NSLocalizedString(
                "This contact is completely verified. All communication will be with the maximum level of privacy.",
                comment: "privacyStatusDescription green")
        case .noColor:
            return NSLocalizedString("Unknown", comment: "privacyStatusDescription no_color")
        }
    }
}
