//
//  PEPExtensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension PEP_color {
    func statusIcon(enabled: Bool = true, white: Bool = true) -> UIImage? {
        if !enabled {
            return nil
        }
        switch self {
        case PEP_color_no_color:
            if white {
                return UIImage(named: "pep-status-unknown")
            }
            return nil
        case PEP_color_red:
            if white {
                return UIImage(named: "pep-status-unsecure")
            }
            return UIImage(named: "pep-status-red")
        case PEP_color_yellow:
            if white {
                return UIImage(named: "pep-status-secure")
            }
            return UIImage(named: "pep-status-yellow")
        case PEP_color_green:
            if white {
                return UIImage(named: "pep-status-secure-trusted")
            }
            return UIImage(named: "pep-status-green")
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
    func pepColor() -> PEP_color {
        return PEPUtil.pEpColor(pEpRating: self)
    }

    func uiColor() -> UIColor? {
        return PEPUtil.pEpColor(pEpRating: self).uiColor()
    }

    func statusIcon() -> UIImage? {
        let color = pepColor()
        return color.statusIcon()
    }
}
