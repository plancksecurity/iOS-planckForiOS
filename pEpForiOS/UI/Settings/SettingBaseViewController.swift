//
//  SettingBaseViewController.swift
//  pEp
//
//  Created by Andreas Buff on 19.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Base ViewController for settings that can be switched on/off
class SettingSwitchViewController: BaseViewController {
    @IBOutlet weak var `switch`: UISwitch!
    /// Short description shown to the user in front of the switch.
    @IBOutlet weak var switchDescription: UILabel!
    /// Texfield with a lot of space to explain the setting.
    @IBOutlet weak var longDescription: UITextView!

    var viewModel : settingsSwitchViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSwitchValue()
    }

    @IBAction func switchChanged(_ sender: Any) {
        handleSwitchChange()
    }

    /// Override to handle switch value changes triggered by the user
    func handleSwitchChange() {
        Log.shared.errorAndCrash(component: #function,
                                 errorString: "Pure virtual. Handle in subclass.")
    }

    /// Overrride to set the switches initial value
    func setSwitchValue() {
        Log.shared.errorAndCrash(component: #function,
                                 errorString: "Pure virtual. Handle in subclass.")
    }
}

/*

 Sync Trash Folder

If enabled, messages in the Trash folder are synced with other devices.

 */

/*

Enable Protected Subject

If enabled, message subjects are also protected.
 */
