//
//  LogViewController.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 02/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

class LogViewController: UIViewController {

    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var enableLogSwitch: UISwitch!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Log.checkEnabled() { enabled in
            GCD.onMain {
                self.enableLogSwitch.isOn = enabled
                if self.enableLogSwitch.isOn {
                    Log.checklog() { logString in
                        GCD.onMain {
                            self.logTextView.text = logString
                        }
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func copyAction(_ sender: Any) {
        Log.checklog() { logString in
            GCD.onMain {
                UIPasteboard.general.string = logString
            }
        }
    }

    @IBAction func enableAction(_ sender: Any) {
        if enableLogSwitch.isOn {
            Log.enableLog()
        } else {
            Log.disableLog()
        }
    }
}
