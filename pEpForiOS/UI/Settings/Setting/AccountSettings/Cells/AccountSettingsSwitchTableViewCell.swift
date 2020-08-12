//
//  AccountSettingsSwitchTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 28/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

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
        titleLabel.textColor = isGrayedOut ? .pEpTextDark : .gray
        switchItem.isOn = row.isOn
        switchItem.isUserInteractionEnabled = isGrayedOut
        switchItem.onTintColor = isGrayedOut ? UIColor.pEpGreen : UIColor.pEpGreyBackground
    }

    /// Configure the cell with the row
    /// - Parameter row: The row to configure the cell
    public func configure(with row : AccountSettingsViewModel.SwitchRow) {
        self.row = row
        titleLabel.text = row.title
        titleLabel.textColor = .pEpTextDark
        switchItem.isOn = row.isOn
        switchItem.onTintColor = .pEpGreen
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
        titleLabel.font = UIFont.pepFont(style: .body, weight: .regular)
    }
}
