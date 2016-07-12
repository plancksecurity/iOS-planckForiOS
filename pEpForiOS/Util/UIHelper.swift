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
     Get the color for a privacy status from the PEP_color.
     */
    static func backgroundColorFromPepColor(pepColor: PrivacyColor) -> UIColor? {
        return UIColor.redColor()
    }
}