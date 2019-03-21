//
//  UIHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PEPObjCAdapterFramework

class UIHelper {
    static func variableCellHeightsTableView(_ tableView: UITableView) {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }
    
    static func labelFromContact(_ contact: CdIdentity) -> UILabel {
        let l = UILabel()
        l.text = contact.address
        return l
    }

    /**
     Put a String into a label. If the String is empty, hide the label.
     */
    static func putString(_ string: String?, toLabel: UILabel?) {
        guard let label = toLabel else {
            return
        }
        if let theString = string, !theString.isEmpty {
            label.isHidden = false
            label.text = theString
        } else {
            label.isHidden = true
        }
    }
    
    static func cleanHtml(_ string: String?) -> String? {
        guard let str = string else { return string }
        return str.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }

    /**
     Makes label bold, using the system font.
     */
    static func boldifyLabel(_ label: UILabel) {
        let size = label.font.pointSize
        let font = UIFont.boldSystemFont(ofSize: size)
        label.font = font
    }

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

    /**
     Get the UIColor for an identity (in a text field or label) for an (abstract) pEp color.
     This might, or might not, be the same,
     as `sendButtonBackgroundColorFromPepColor:PrivacyColor`.
     */
    static func textBackgroundUIColorFromPrivacyColor(_ pepColor: PEPColor) -> UIColor? {
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
     Gives the label a background color depending on the given privacy color.
     If the privacy color is `PrivacyColor.NoColor` the default color is used.
     */
    static func setBackgroundColor(
        _ privacyColor: PEPColor, forLabel label: UILabel, defaultColor: UIColor?) {
        if privacyColor != PEPColor.noColor {
            let uiColor = UIHelper.textBackgroundUIColorFromPrivacyColor(privacyColor)
            label.backgroundColor = uiColor
        } else {
            label.backgroundColor = defaultColor
        }
    }

    /**
     Creates a 1x1 point size image filled with the given color. Useful for giving buttons
     a background color.
     */
    static func imageFromColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0),
                          size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
