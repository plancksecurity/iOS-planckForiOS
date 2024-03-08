//
//  AccountSettingsSwitchTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 28/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

import PlanckToolbox

final class AccountSettingsSwitchTableViewCell: UITableViewCell {

    static let identifier = "SwitchTableViewCell"

    @IBOutlet weak var switchItem: UISwitch!
    @IBOutlet private weak var titleLabel: UILabel!

    private var row : AccountSettingsViewModel.SwitchRow?

    /// Configure the cell with the row and specify if it has to be grayed out.
    /// - Parameters:
    ///   - row: The row to configure the cell
    ///   - isGrayedOut: indicates if the row has to be grayed out. 
    public func configure(with row : AccountSettingsViewModel.SwitchRow, isGrayedOut: Bool) {
        self.row = row
        titleLabel.text = row.title
        if UITraitCollection.current.userInterfaceStyle == .light {
            titleLabel.textColor = isGrayedOut ? .pEpTextDark : .gray
        } else {
            titleLabel.textColor = isGrayedOut ? UIColor.label : .gray
        }
        switchItem.isOn = row.isOn
        switchItem.isUserInteractionEnabled = isGrayedOut
        let primary = UIColor.primary()
        switchItem.onTintColor = isGrayedOut ? primary : UIColor.secondary
    }

    /// Configure the cell with the row
    /// - Parameter row: The row to configure the cell
    public func configure(with row : AccountSettingsViewModel.SwitchRow) {
        self.row = row
        titleLabel.text = row.title
        if UITraitCollection.current.userInterfaceStyle == .light {
            titleLabel.textColor = .pEpTextDark
        } else {
            titleLabel.textColor = UIColor.label
        }
        switchItem.isOn = row.isOn
        switchItem.onTintColor = UIColor.primary()
    }

    @IBAction func switchChanged(_ sender: UISwitch) {
        guard let row = row else {
            //This should never happen
            Log.shared.error("Without a row the action cant be performed")
            sender.setOn(!sender.isOn, animated: true)
            return
        }
        row.action(sender.isOn)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont.planckFont(style: .body, weight: .regular)
    }
}
