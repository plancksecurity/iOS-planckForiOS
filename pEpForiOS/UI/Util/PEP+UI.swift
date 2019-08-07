//
//  PEPExtensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import PEPObjCAdapterFramework
import MessageModel

extension PEPColor {
    /**
     The icon suitable for indicating the rating of an outgoing message.
     */
    func statusIcon(enabled: Bool = true) -> UIImage? {
        switch self {
        case PEPColor.noColor:
            return UIImage(named: "pEp-status-grey")
        case PEPColor.red:
            return UIImage(named: "pEp-status-red")
        case .yellow:
            if enabled {
                return UIImage(named: "pEp-status-yellow")
            } else {
                return UIImage(named: "pEp-status-yellow-disabled")
            }
        case .green:
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
        case PEPColor.noColor:
            return UIImage(named: "pEp-status-grey_white-border")
        case PEPColor.red:
            return UIImage(named: "pEp-status-red_white-border")
        case .yellow:
            return UIImage(named: "pEp-status-yellow_white-border")
        case .green:
            return UIImage(named: "pEp-status-green_white-border")
        default:
            return nil
        }
    }

    func uiColor() -> UIColor? {
        switch self {
        case PEPColor.noColor:
            return UIColor.gray
        case PEPColor.red:
            return UIColor.pEpRed
        case .yellow:
            return UIColor.pEpYellow
        case .green:
            return UIColor.pEpGreen
        default:
            return nil
        }
    }
}

extension PEPRating {
    func uiColor() -> UIColor? {
        return PEPUtils.pEpColor(pEpRating: self).uiColor()
    }

    func statusIcon() -> UIImage? {
        let color = pEpColor()
        return color.statusIcon()
    }
}
