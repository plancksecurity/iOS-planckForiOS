//
//  CreditsViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import WebKit

import PlanckToolbox
import pEp4iosIntern

class CreditsViewController: UIViewController {
    @IBOutlet public weak var verboseLoggingSwitch: UISwitch!
    
    private var viewModel = CreditsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Credits", comment: "Credits - title")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        verboseLoggingSwitch.isOn = AppSettings.shared.verboseLogginEnabled
        verboseLoggingSwitch.onTintColor = UITraitCollection.current.userInterfaceStyle == .dark ? .primaryDarkMode : .primaryLightMode
    }

    @IBAction public func switchedVerboseLoggingEnabled(_ sender: UISwitch) {
        viewModel.handleVerboseLoggingSwitchChange(newValue: sender.isOn)
    }
}
