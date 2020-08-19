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

    /// The icon suitable for indicating the pEp rating of a message.
    ///
    /// - Parameter enabled: whether or not pEp protection is enabled
    /// - Returns: icon suitable for indicating the pEp rating of a message
    func statusIconForMessage(enabled: Bool = true, withText : Bool = true) -> UIImage? {
        switch self {
        case PEPColor.noColor:
            return nil
        case PEPColor.red:
            return withText ? UIImage(named: "pEp-status-msg-red") : UIImage(named: "pEp-status-red_white-border")
        case .yellow:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-yellow") : UIImage(named: "pEp-status-yellow_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-secure") : nil
            }
        case .green:
            if enabled {
                return withText ? UIImage(named: "pEp-status-msg-green") : UIImage(named: "pEp-status-green_white-border")
            } else {
                return withText ? UIImage(named: "pEp-status-msg-disabled-trusted") : nil
            }
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
            return nil
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
    var isNoColor: Bool {
        get {
            return pEpColor() == PEPColor.noColor
        }
    }

    func statusIcon() -> UIImage? {
        let color = pEpColor()
        return color.statusIconForMessage()
    }
}
