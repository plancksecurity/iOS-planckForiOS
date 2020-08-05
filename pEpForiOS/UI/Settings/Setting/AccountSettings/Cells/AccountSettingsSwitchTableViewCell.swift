//
//  AccountSettingsSwitchTableViewCell.swift
//  pEp
//
//  Created by Martin Brude on 28/05/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol AccountSettingsSwitchTableViewCellDelegate: class {
    func switchValueChanged(of rowType: AccountSettingsViewModel.RowType, to newValue: Bool)
}

final class AccountSettingsSwitchTableViewCell: UITableViewCell {

    static let identifier = "SwitchTableViewCell"

    @IBOutlet weak var switchItem: UISwitch!
    @IBOutlet private weak var titleLabel: UILabel!

    private var row : AccountSettingsViewModel.SwitchRow?

    weak var delegate : AccountSettingsSwitchTableViewCellDelegate?

    public func configure(with row : AccountSettingsViewModel.SwitchRow, isGrayedOut: Bool) {
        self.row = row
        titleLabel.text = row.title
        titleLabel.textColor = isGrayedOut ? .pEpTextDark : .gray
        switchItem.isOn = row.isOn
        switchItem.isUserInteractionEnabled = isGrayedOut
        switchItem.onTintColor = isGrayedOut ? UIColor.pEpGreen : UIColor.pEpGreyBackground
    }

    @IBAction func switchChanged(_ sender: UISwitch) {
        guard let row = row else {
            //This should never happen
            Log.shared.error("Without a row the action cant be performed")
            sender.setOn(!sender.isOn, animated: true)
            return
        }
        delegate?.switchValueChanged(of: row.type, to: sender.isOn)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont.pepFont(style: .body, weight: .regular)
    }
}
