//
//  SMTPSettingsTableView.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public struct ModelSMTPSettingsInfoTable {

    public var SMTPServer:String = "default.imap.server"
    public var SMTPPort:UInt16 = 993
    public var transportSecuritySMTP:String = "NONE"

    public init(SMTPServer:String,SMTPPort:UInt16,transportSecuritySMTP:String) {
        self.SMTPServer = SMTPServer
        self.SMTPPort = SMTPPort
        self.transportSecuritySMTP = transportSecuritySMTP
    }
}

class SMTPSettingsTableView: UITableViewController {

    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    var appConfig: AppConfig?
    var mailSettings = MailSettingParameters()
    var model = ModelSMTPSettingsInfoTable(SMTPServer:"default.imap.server",SMTPPort: 993,transportSecuritySMTP: "NONE")

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func alertWithSecurityValues(sender: AnyObject) {
        let alertController = UIAlertController(title: "Security protocol", message: "Choose a Security protocol for your accont", preferredStyle: .ActionSheet)
        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in}
        alertController.addAction(CancelAction)
        let StartTLSAction = UIAlertAction(title: "Start TLS", style: .Default) { (action) in
            self.transportSecurity.setTitle("Start TLS >", forState: .Normal)
        }
        alertController.addAction(StartTLSAction)
        let TLSAction = UIAlertAction(title: "TLS", style: .Default) { (action) in
            self.transportSecurity.setTitle("TLS >", forState: .Normal)
        }
        alertController.addAction(TLSAction)
        let NONEAction = UIAlertAction(title: "NONE", style: .Default) { (action) in
            self.transportSecurity.setTitle("NONE >", forState: .Normal)
        }
        alertController.addAction(NONEAction)
        self.presentViewController(alertController, animated: true) {}
        model.transportSecuritySMTP = (transportSecurity.titleLabel?.text)!
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        mailSettings.serverhostSMTP = serverValue.text!
        let portSMTPAux:String = portValue.text!
        mailSettings.portSMTP = UInt16(portSMTPAux)!

        /*var x = 3
        let connect = ConnectInfo.init(email: mailSettings.email!, imapPassword: mailSettings.password!,
        imapServerName: mailSettings.serverhostIMAP!, imapServerPort: mailSettings.portIMAP!,
        imapTransport:ConnectionTransport(rawValue: x)!,smtpServerName: mailSettings.serverhostSMTP!,
        smtpServerPort: mailSettings.portSMTP!, smtpTransport: ConnectionTransport.Plain)

        _ = appConfig?.grandOperator.verifyConnection(connect, completionBlock: { (error) in
            GCD.onMain({
                let account:IAccount = (self.appConfig?.model.insertAccountFromConnectInfo(connect))!
            })
        })*/
        if segue.identifier == "inboxMail" {
            if let destination = segue.destinationViewController as? EmailListViewController {
            }
        }
    }
}
