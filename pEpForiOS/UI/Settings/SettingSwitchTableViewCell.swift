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
        handleSwitchChange()
    }

    func setUpView() {
        self.switchDescription.text = viewModel?.title
        setSwitchValue()
    }

    func handleSwitchChange() {
        if let vm = viewModel {
            if let keySyncvm = vm as? KeySyncSwitchSettingViewModel {
                showKeySyncAlertIfNeeded(viewModel: keySyncvm)
            } else {
                vm.setSwitch(value: switchItem.isOn)
            }
        }
    }

    func setSwitchValue() {
        if let vm = viewModel {
            switchItem.setOn(vm.switchValue(), animated: false)
        }
    }

    func showKeySyncAlertIfNeeded(viewModel: KeySyncSwitchSettingViewModel) {
        if viewModel.isGrouped() {
            let title = NSLocalizedString("Disable pEp Sync", comment: "Leave device group confirmation")
            let comment = NSLocalizedString("if you disable pEps sybc, your device group will be dissolved. are you sure you want to disabre pep Sync?", comment: "Leave device group confirmation comment")

            let alert = UIAlertController.pEpAlertController(title: title, message: comment, preferredStyle: .alert)
            let cancelAction = alert.action(NSLocalizedString("Cancel", comment: "keysync alert leave device group cancel"), .cancel)
            let disableAction = alert.action("Disable", .default) { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash(message: "lost myself")
                    return
                }
                viewModel.setSwitch(value: me.switchItem.isOn)
            }
            alert.addAction(cancelAction)
            alert.addAction(disableAction)
            //missing present should be moved to tableview
        } else {
            viewModel.setSwitch(value: switchItem.isOn)
        }
    }
}
