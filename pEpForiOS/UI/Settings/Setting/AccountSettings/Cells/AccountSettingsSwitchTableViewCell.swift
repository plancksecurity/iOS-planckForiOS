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

    @IBOutlet private weak var switchItem: UISwitch!
    @IBOutlet private weak var titleLabel: UILabel!

    public func configure(with row : AccountSettingsViewModel2.SwitchRow? = nil) {
        guard let row = row else {
            return
        }
        titleLabel.text = row.title
        switchItem.isOn = row.isOn
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont.pepFont(style: .body, weight: .regular)
    }

}
