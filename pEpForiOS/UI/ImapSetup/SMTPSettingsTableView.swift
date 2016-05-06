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

    var appConfig: AppConfig?
    var mailSettings = MailSettingParameters()

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        mailSettings.serverhostSMTP = serverValue.text!
        let portSMTPAux:String = portValue.text!
        mailSettings.portSMTP = UInt16(portSMTPAux)!


    let connect = ConnectInfo.init(
        email: mailSettings.email!, imapPassword: mailSettings.password!,
        imapServerName: mailSettings.serverhostIMAP!, imapServerPort: mailSettings.portIMAP!,
        imapTransport:ConnectionTransport.Plain, smtpServerName: mailSettings.serverhostSMTP!,
        smtpServerPort: mailSettings.portSMTP!, smtpTransport: ConnectionTransport.Plain)

        _ = appConfig?.grandOperator.verifyConnection(connect, completionBlock: { (error) in
            GCD.onMain({
                let account:IAccount = (self.appConfig?.model.insertAccountFromConnectInfo(connect))!
            })
        })
        if segue.identifier == "inboxMail" {
            if let destination = segue.destinationViewController as? EmailListViewController {
            }
        }
    }
}
