//
//  PEPExtensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension PEP_color {
    /**
     The icon suitable for indicating the rating of an outgoing message.
     */
    func statusIcon(enabled: Bool = true) -> UIImage? {
        switch self {
        case PEP_color_no_color:
            return UIImage(named: "pEp-status-grey")
        case PEP_color_red:
            return UIImage(named: "pEp-status-red")
        case PEP_color_yellow:
            if enabled {
                return UIImage(named: "pEp-status-yellow")
            } else {
                return UIImage(named: "pEp-status-yellow-disabled")
            }
        case PEP_color_green:
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
        case PEP_color_no_color:
            return UIImage(named: "pEp-status-grey_white-border")
        case PEP_color_red:
            return UIImage(named: "pEp-status-red_white-border")
        case PEP_color_yellow:
            return UIImage(named: "pEp-status-yellow_white-border")
        case PEP_color_green:
            return UIImage(named: "pEp-status-green_white-border")
        default:
            return nil
        }
    }

    func uiColor() -> UIColor? {
        switch self {
        case PEP_color_no_color:
            return UIColor.gray
        case PEP_color_red:
            return UIColor.pEpRed
        case PEP_color_yellow:
            return UIColor.pEpYellow
        case PEP_color_green:
            return UIColor.pEpGreen
        default:
            return nil
        }
    }
}

extension PEPRating {
    func pEpColor() -> PEP_color {
        return PEPUtil.pEpColor(pEpRating: self)
    }

    func uiColor() -> UIColor? {
        return PEPUtil.pEpColor(pEpRating: self).uiColor()
    }

    func statusIcon() -> UIImage? {
        let color = pEpColor()
        return color.statusIcon()
    }
}
