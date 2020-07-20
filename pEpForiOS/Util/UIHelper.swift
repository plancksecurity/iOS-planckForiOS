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

    /// Configures the table view to support dynamic cells, footer and header height based on its content.
    /// - Parameter tableView: The table view to configure
    static func variableContentHeight(_ tableView: UITableView) {
        variableCellHeightsTableView(tableView)
        variableSectionHeadersHeightTableView(tableView)
        variableSectionFootersHeightTableView(tableView)
    }

    /// Configures the table view to support dynamic cells height based on its content.
    /// - Parameter tableView: The table view to configure
    static func variableCellHeightsTableView(_ tableView: UITableView) {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }

    /// Configures the table view to support dynamic header height based on its content.
    /// - Parameter tableView: The table view to configure
    static func variableSectionHeadersHeightTableView(_ tableView: UITableView) {
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 25
    }

    /// Configures the table view to support dynamic footer height based on its content.
    /// - Parameter tableView: The table view to configure
    static func variableSectionFootersHeightTableView(_ tableView: UITableView) {
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 25
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
