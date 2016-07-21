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
     Get the UIColor for a privacy status from the `PrivacyColor`.
     */
    static func backgroundColorFromPepColor(pepColor: PrivacyColor) -> UIColor? {
        return UIColor.redColor()
    }

    /**
     Get the UIColor for the background image of a send button for an (abstract) pEp color.
     */
    static func sendButtonBackgroundColorFromPepColor(pepColor: PrivacyColor) -> UIColor? {
        switch pepColor {
        case .Green:
            return UIColor.greenColor()
        case .Yellow:
            return UIColor.yellowColor()
        case .Red:
            return UIColor.redColor()
        case .NoColor:
            return nil
        }
    }

    /**
     Get the UIColor for a recipient (in a text field) for an (abstract) pEp color.
     This might, or might not, be the same,
     as `sendButtonBackgroundColorFromPepColor:PrivacyColor`.
     */
    static func recipientTextColorFromPepColor(pepColor: PrivacyColor) -> UIColor? {
        switch pepColor {
        case .Green:
            return UIColor.greenColor()
        case .Yellow:
            return UIColor.yellowColor()
        case .Red:
            return UIColor.redColor()
        case .NoColor:
            return nil
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
}