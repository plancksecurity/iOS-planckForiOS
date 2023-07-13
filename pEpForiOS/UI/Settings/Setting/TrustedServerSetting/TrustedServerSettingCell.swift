//
//  TrustedServerSettingCell.swift
//  pEp
//
//  Created by Andreas Buff on 17.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol TrustedServerSettingCellDelegate: AnyObject {
    func trustedServerSettingCell(sender: TrustedServerSettingCell, didChangeSwitchValue newValue: Bool)
}

class TrustedServerSettingCell: UITableViewCell {
   static let storyboardId = "TrustedServerSettingCell"
    @IBOutlet weak var onOfSwitch: UISwitch!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var address: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        onOfSwitch.onTintColor = UITraitCollection.current.userInterfaceStyle == .dark ? .primaryDarkMode : .primaryLightMode
    }

    weak var delegate: TrustedServerSettingCellDelegate?

    @IBAction func switchToggled(_ sender: UISwitch) {
        delegate?.trustedServerSettingCell(sender: self, didChangeSwitchValue: sender.isOn)
    }
}
