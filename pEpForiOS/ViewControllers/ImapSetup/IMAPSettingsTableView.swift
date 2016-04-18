//
//  MyTableIMAPSettings.swift
//  pEpForiOS
//
//  Created by ana on 15/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class IMAPSettingsTableView: UITableViewController {

   
    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!


    var mailParameters = MailSettingParameters(email: " ", username: " ", password: " ", serverhostIMAP: " ", portIMAP: " ", transportSecurityIMAP: " ", serverhostSMTP: " ", portSMTP: " ",transportSecuritySMTP: " ")

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SMTPSettings" {
            mailParameters.serverhostIMAP = serverValue.text!
            mailParameters.portIMAP = portValue.text!
            if let destination = segue.destinationViewController as? SMTPSettingsTableView {
                destination.mailParameters = mailParameters
            }
        }
    }
}
