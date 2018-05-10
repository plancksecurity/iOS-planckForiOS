//
//  PEPExtensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension PEP_color {
    func statusIcon(enabled: Bool = true) -> UIImage? {
        switch self {
        case PEP_color_no_color:
            return nil
        case PEP_color_red:
            return UIImage(named: "pEp-status-red")
        case PEP_color_yellow:
            if enabled {
                return UIImage(named: "pEp-status-yellow")
            } else {
                return UIImage(named: "pEp-status-yellow-gray")
            }
        case PEP_color_green:
            if enabled {
                return UIImage(named: "pEp-status-green")
            } else {
                return UIImage(named: "pEp-status-green-gray")
            }
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

extension PEP_rating {
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
