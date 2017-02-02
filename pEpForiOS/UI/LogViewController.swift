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
    @IBOutlet weak var eableLogSwitch: UISwitch!


    override func viewDidLoad() {
        super.viewDidLoad()
        logTextView.text = Log.getlog()
        if eableLogSwitch.isOn {
            logTextView.text = Log.getlog()
        } else {
            logTextView.text = ""
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func copyAction(_ sender: Any) {

        UIPasteboard.general.string = Log.getlog()

    }
    @IBAction func enableAction(_ sender: Any) {

        if eableLogSwitch.isOn {
            logTextView.text = Log.getlog()
        } else {
            logTextView.text = ""
        }
    }
}
