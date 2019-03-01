//
//  PEPExtensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension PEPColor {
    /**
     The icon suitable for indicating the rating of an outgoing message.
     */
    func statusIcon(enabled: Bool = true) -> UIImage? {
        switch self {
        case PEPColorNoColor:
            return UIImage(named: "pEp-status-grey")
        case PEPColorRed:
            return UIImage(named: "pEp-status-red")
        case PEPColorYellow:
            if enabled {
                return UIImage(named: "pEp-status-yellow")
            } else {
                return UIImage(named: "pEp-status-yellow-disabled")
            }
        case PEPColorGreen:
            if enabled {
                return UIImage(named: "pEp-status-green")
            } else {
                return UIImage(named: "pEp-status-green-disabled")
            }
        default:
            return nil
        }
    }

    /**
     Similar to `statusIcon`, but for a message in a local folder and embedded
     in the contact's profile picture.
     Typically includes a white border, and doesn't support disabled protection.
     */
    func statusIconInContactPicture() -> UIImage? {
        switch self {
        case PEPColorNoColor:
            return UIImage(named: "pEp-status-grey_white-border")
        case PEPColorRed:
            return UIImage(named: "pEp-status-red_white-border")
        case PEPColorYellow:
            return UIImage(named: "pEp-status-yellow_white-border")
        case PEPColorGreen:
            return UIImage(named: "pEp-status-green_white-border")
        default:
            return nil
        }
    }
}
