//
//  PEPExtensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

extension PEP_color {
    func statusIcon() -> UIImage? {
        switch self {
        case PEP_color_no_color:
            return nil
        case PEP_color_red:
            return UIImage(named: "pep-user-status-red")
        case PEP_color_yellow:
            return UIImage(named: "pep-user-status-yellow")
        case PEP_color_green:
            return UIImage(named: "pep-user-status-green")
        default:
            return nil
        }
    }

    func uiColor() -> UIColor? {
        switch self {
        case PEP_color_no_color:
            return nil
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
}
