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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }
    static func variableSectionHeaderHeightsTableView(_ tableView: UITableView) {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 25
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
}
