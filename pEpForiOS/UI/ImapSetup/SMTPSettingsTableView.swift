//
//  SMTPSettingsTableView.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class SMTPSettingsTableView: UITableViewController {


 
    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!

    var mailParameters = MailSettingParameters()

    override func viewDidLoad() {
        super.viewDidLoad()
        print (mailParameters.email)
        print (mailParameters.username)
        print (mailParameters.password)

        print (mailParameters.serverhostIMAP)
        print (mailParameters.portIMAP)
        print (mailParameters.transportSecurityIMAP)

        print (mailParameters.serverhostSMTP)
        print (mailParameters.portSMTP)
        print (mailParameters.transportSecuritySMTP)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "inboxMail" {
            mailParameters.serverhostSMTP = serverValue.text!
            mailParameters.portSMTP = portValue.text!
            if let destination = segue.destinationViewController as? MailTableView {
                destination.mailParameters = mailParameters
            }
        }
    }
}
