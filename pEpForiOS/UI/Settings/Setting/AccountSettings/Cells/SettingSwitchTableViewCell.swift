//
//  SettingSwitchTableViewCell.swift
//  pEp
//
//  Created by Andreas Buff on 19.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol SwitchCellDelegate: AnyObject {
    func switchSettingCell(_ sender: SettingSwitchTableViewCell, didChangeSwitchStateTo newValue: Bool)
}

/// Base ViewController for settings that can be switched on/off
class SettingSwitchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var switchItem : UISwitch!
    
    /// Short description shown to the user in front of the switch.
    @IBOutlet weak var switchDescription: UILabel!

    weak var delegate: SwitchCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        switchItem.onTintColor = UIColor.primary()
    }

    @IBAction func switchChanged(_ sender: Any) {
        delegate?.switchSettingCell(self, didChangeSwitchStateTo: switchItem.isOn)
    }
}
