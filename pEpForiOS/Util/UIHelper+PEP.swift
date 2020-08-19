//
//  UIHelper+PEP.swift
//  pEp
//
//  Created by Alejandro Gelos on 25/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

// MARK: - UIHelper+PEP

extension UIHelper {
    /**
     Get the UIColor for the background image of a send button for an (abstract) pEp color.
     */
    static func sendButtonBackgroundColorFromPepColor(_ pepColor: PEPColor) -> UIColor? {
        switch pepColor {
        case .green:
            return UIColor.green
        case .yellow:
            return UIColor.yellow
        case PEPColor.red:
            return UIColor.red
        default:
            return nil
        }
    }

    /**
     Cell background color in trustwords cell for indicating the rating of a contact.
     */
    static func trustWordsCellBackgroundColorFromPepColor(_ pepColor: PEPColor) -> UIColor? {
        return sendButtonBackgroundColorFromPepColor(pepColor)
    }

    /// Get the UIColor for an identity (in a text field or label) for an (abstract) pEp color.
    /// This might, or might not, be the same,
    /// as `sendButtonBackgroundColorFromPepColor:PrivacyColor`.
    static func textBackgroundUIColorFromPrivacyColor(_ color: Color) -> UIColor? {
        switch color {
        case .green:
            return UIColor.green
        case .yellow:
            return UIColor.yellow
        case .red:
            return UIColor.red
        default:
            return nil
        }
    }
}
