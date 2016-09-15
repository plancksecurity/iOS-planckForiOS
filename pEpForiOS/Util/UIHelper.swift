//
//  UIHelper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class UIHelper {
    static func variableCellHeightsTableView(tableView: UITableView) {
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
    }

    static func labelFromContact(contact: Contact) -> UILabel {
        let l = UILabel.init()
        l.text = contact.displayString()
        return l
    }

    static func dateFormatterEmailList() -> NSDateFormatter {
        let formatter = NSDateFormatter.init()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }

    static func dateFormatterEmailDetails() -> NSDateFormatter {
        return dateFormatterEmailList()
    }

    /**
     Put a String into a label. If the String is empty, hide the label.
     */
    static func putString(string: String?, toLabel: UILabel?) {
        guard let label = toLabel else {
            return
        }
        if string?.characters.count > 0 {
            label.hidden = false
            label.text = string!
        } else {
            label.hidden = true
        }
    }

    /**
     Makes label bold, using the system font.
     */
    static func boldifyLabel(label: UILabel) {
        let size = label.font.pointSize
        let font = UIFont.boldSystemFontOfSize(size)
        label.font = font
    }

    /**
     Get the UIColor for the background image of a send button for an (abstract) pEp color.
     */
    static func sendButtonBackgroundColorFromPepColor(pepColor: PEP_color) -> UIColor? {
        switch pepColor {
        case PEP_color_green:
            return UIColor.greenColor()
        case PEP_color_yellow:
            return UIColor.yellowColor()
        case PEP_color_red:
            return UIColor.redColor()
        default:
            return nil
        }
    }

    /**
     Cell background color in trustwords cell for indicating the rating of a contact.
     */
    static func trustWordsCellBackgroundColorFromPepColor(pepColor: PEP_color) -> UIColor? {
        return sendButtonBackgroundColorFromPepColor(pepColor)
    }

    /**
     Get the UIColor for an identity (in a text field or label) for an (abstract) pEp color.
     This might, or might not, be the same,
     as `sendButtonBackgroundColorFromPepColor:PrivacyColor`.
     */
    static func textBackgroundUIColorFromPrivacyColor(pepColor: PEP_color) -> UIColor? {
        switch pepColor {
        case PEP_color_green:
            return UIColor.greenColor()
        case PEP_color_yellow:
            return UIColor.yellowColor()
        case PEP_color_red:
            return UIColor.redColor()
        default:
            return nil
        }
    }

    /**
     Gives the label a background color depending on the given privacy color.
     If the privacy color is `PrivacyColor.NoColor` the default color is used.
     */
    static func setBackgroundColor(
        privacyColor: PEP_color, forLabel label: UILabel, defaultColor: UIColor?) {
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
    static func imageFromColor(color: UIColor) -> UIImage {
        let rect = CGRect.init(origin: CGPoint.init(x: 0, y: 0),
                               size: CGSize.init(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }

    /**
     Displays an alert showing an error, with just on ok button and no other interaction.
     */
    static func displayError(error: NSError?, controller: UIViewController,
                             title: String? = nil) {
        if let err = error {
            let message = err.localizedDescription
            displayErrorMessage(message, controller: controller, title: title)
        }
    }

    /**
     Displays an alert showing a message, with just on ok button and no other interaction.
     */
    static func displayErrorMessage(errorMessage: String, controller: UIViewController,
                             title: String? = nil) {
        var theTitle: String! = title
        if theTitle == nil {
            theTitle = NSLocalizedString(
                "Error", comment: "General error alert title")
        }
        let alert = UIAlertController.init(
            title: theTitle, message: errorMessage, preferredStyle: .Alert)
        let okTitle = NSLocalizedString(
            "Ok", comment: "OK for error alert (no other interaction possible)")
        let action = UIAlertAction.init(
            title: okTitle, style: .Default, handler: nil)
        alert.addAction(action)
        controller.presentViewController(alert, animated: true, completion: nil)
    }
}