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

    var viewModel: SwitchSettingCellViewModelProtocol?

    @IBAction func switchChanged(_ sender: Any) {
        if let vm = viewModel {
            vm.setSwitch(value: switchItem.isOn)
        }
    }

    func setUpView() {
        self.switchDescription.text = viewModel?.title
        setSwitchValue()
    }

    func setSwitchValue() {
        if let vm = viewModel {
            switchItem.setOn(vm.switchValue(), animated: false)
        }
    }
}
