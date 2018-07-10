//
//  SettingBaseViewController.swift
//  pEp
//
//  Created by Andreas Buff on 19.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Base ViewController for settings that can be switched on/off
class SettingSwitchTableViewCell: UITableViewCell {
    @IBOutlet weak var switchItem : UISwitch!
    /// Short description shown to the user in front of the switch.
    @IBOutlet weak var switchDescription: UILabel!
    /// Texfield with a lot of space to explain the setting.

    var viewModel : SettingSwitchProtocol?

    @IBAction func switchChanged(_ sender: Any) {
        handleSwitchChange()
    }

    func setUpView() {
        self.switchDescription.text = viewModel?.title
    }

    func handleSwitchChange() {
        if let vm = viewModel {
            vm.switchAction(value: switchItem.isOn)
        }
    }

    func setSwitchValue() {
        if let vm = viewModel {
            switchItem.setOn(vm.switchValue, animated: false)
        }
    }
}
