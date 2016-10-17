//
//  UIHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class UIHelper {
    static func variableCellHeightsTableView(_ tableView: UITableView) {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }

    static func labelFromContact(_ contact: CdContact) -> UILabel {
        let l = UILabel.init()
        l.text = contact.displayString()
        return l
    }

    static func dateFormatterEmailList() -> DateFormatter {
        let formatter = DateFormatter.init()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    static func dateFormatterEmailDetails() -> DateFormatter {
        return dateFormatterEmailList()
    }

    /**
     Put a String into a label. If the String is empty, hide the label.
     */
    static func putString(_ string: String?, toLabel: UILabel?) {
        guard let label = toLabel else {
            return
        }
        if string?.characters.count > 0 {
            label.isHidden = false
            label.text = string!
        } else {
            label.isHidden = true
        }
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
    static func sendButtonBackgroundColorFromPepColor(_ pepColor: PEP_color) -> UIColor? {
        switch pepColor {
        case PEP_color_green:
            return UIColor.green
        case PEP_color_yellow:
            return UIColor.yellow
        case PEP_color_red:
            return UIColor.red
        default:
            return nil
        }
    }

    /**
     Cell background color in trustwords cell for indicating the rating of a contact.
     */
    static func trustWordsCellBackgroundColorFromPepColor(_ pepColor: PEP_color) -> UIColor? {
        return sendButtonBackgroundColorFromPepColor(pepColor)
    }

    /**
     Get the UIColor for an identity (in a text field or label) for an (abstract) pEp color.
     This might, or might not, be the same,
     as `sendButtonBackgroundColorFromPepColor:PrivacyColor`.
     */
    static func textBackgroundUIColorFromPrivacyColor(_ pepColor: PEP_color) -> UIColor? {
        switch pepColor {
        case PEP_color_green:
            return UIColor.green
        case PEP_color_yellow:
            return UIColor.yellow
        case PEP_color_red:
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
        _ privacyColor: PEP_color, forLabel label: UILabel, defaultColor: UIColor?) {
        if privacyColor != PEP_color_no_color {
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
        let rect = CGRect.init(origin: CGPoint.init(x: 0, y: 0),
                               size: CGSize.init(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }

    /**
     Displays an alert showing an error, with just on ok button and no other interaction.
     */
    static func displayError(_ error: NSError?, controller: UIViewController,
                             title: String? = nil) {
        if let err = error {
            let message = err.localizedDescription
            if Thread.current.isMainThread {
                displayErrorMessage(message, controller: controller, title: title)
            } else {
                GCD.onMain() {
                    displayErrorMessage(message, controller: controller, title: title)
                }
            }
        }
    }

    /**
     Displays an alert showing a message, with just on ok button and no other interaction.
     */
    static func displayErrorMessage(_ errorMessage: String, controller: UIViewController,
                             title: String? = nil) {
        var theTitle: String! = title
        if theTitle == nil {
            theTitle = NSLocalizedString(
                "Error", comment: "General error alert title")
        }
        let alert = UIAlertController.init(
            title: theTitle, message: errorMessage, preferredStyle: .alert)
        let okTitle = NSLocalizedString(
            "Ok", comment: "OK for error alert (no other interaction possible)")
        let action = UIAlertAction.init(
            title: okTitle, style: .default, handler: nil)
        alert.addAction(action)
        controller.present(alert, animated: true, completion: nil)
    }
}
