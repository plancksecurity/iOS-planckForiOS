//
//  CreditsViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import WebKit

class CreditsViewController: UIViewController {
    private var viewModel = CreditsViewModel()
    @IBOutlet weak var verboseLoggingSwitch: UISwitch!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        verboseLoggingSwitch.isOn = AppSettings.shared.verboseLogginEnabled
        installLogViewGesture()
    }

    @IBAction func switchedVerboseLoggingEnabled(_ sender: UISwitch) {
        viewModel.handleVerboseLoggingSwitchChange(newValue: sender.isOn)
    }

    private func installLogViewGesture() {
        let secretTapGesture = UITapGestureRecognizer(target: self,
                                                      action: #selector(secretGestureAction(_:)))
        secretTapGesture.numberOfTouchesRequired = 1
        secretTapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(secretTapGesture)
    }
}

extension CreditsViewController: SegueHandlerType {
    /// Identifier of the segues.
    enum SegueIdentifier: String {
        case segueShowLog
    }
}

extension CreditsViewController {
    @IBAction func secretGestureAction(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            performSegue(withIdentifier: SegueIdentifier.segueShowLog, sender: self)
        }
    }
}
