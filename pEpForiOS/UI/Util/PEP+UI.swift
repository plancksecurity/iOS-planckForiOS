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
        case PEPColor_no_color:
            return UIImage(named: "pEp-status-grey")
        case PEPColor_red:
            return UIImage(named: "pEp-status-red")
        case PEPColor_yellow:
            if enabled {
                return UIImage(named: "pEp-status-yellow")
            } else {
                return UIImage(named: "pEp-status-yellow-disabled")
            }
        case PEPColor_green:
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
        case PEPColor_no_color:
            return UIImage(named: "pEp-status-grey_white-border")
        case PEPColor_red:
            return UIImage(named: "pEp-status-red_white-border")
        case PEPColor_yellow:
            return UIImage(named: "pEp-status-yellow_white-border")
        case PEPColor_green:
            return UIImage(named: "pEp-status-green_white-border")
        default:
            return nil
        }
    }

    func uiColor() -> UIColor? {
        switch self {
        case PEPColor_no_color:
            return UIColor.gray
        case PEPColor_red:
            return UIColor.pEpRed
        case PEPColor_yellow:
            return UIColor.pEpYellow
        case PEPColor_green:
            return UIColor.pEpGreen
        default:
            return nil
        }
    }
}

extension PEPRating {
    func pEpColor() -> PEPColor {
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
