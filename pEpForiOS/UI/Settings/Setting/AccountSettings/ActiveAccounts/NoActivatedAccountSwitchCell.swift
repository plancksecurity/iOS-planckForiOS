//
//  NoActivatedAccountSwitchCell.swift
//  pEp
//
//  Created by Martín Brude on 10/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class NoActivatedAccountSwitchCell: UITableViewCell {

    private var row: NoActivatedAccountViewModel.SwitchRow?
    static let identifier = "NoActivatedAccountSwitchCell"

    @IBOutlet weak var switchItem: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont.pepFont(style: .body, weight: .regular)
    }

    /// Configure the cell with the row
    /// - Parameter row: The row to configure the cell
    public func configure(with row : NoActivatedAccountViewModel.SwitchRow) {
        self.row = row
        titleLabel.text = row.title
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .light {
                titleLabel.textColor = .pEpTextDark
            } else {
                titleLabel.textColor = UIColor.label
            }
        } else {
            titleLabel.textColor = .pEpTextDark
        }
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
}
