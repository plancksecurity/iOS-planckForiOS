//
//  SMTPSettingsTableView.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public struct ModelSMTPSettingsInfoTable {

    public var SMTPServer: String = "default.imap.server"
    public var SMTPPort: UInt16 = 993
    public var transportSecuritySMTP: String = "NONE"
    public var transportSmtp: ConnectionTransport?

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

    /**
     - Todo: Blueprint for updating the view from the model.
     */
    func updateView() {
        if let transport = model.transportSmtp {
            switch transport {
            case .StartTLS:
                self.transportSecurity.setTitle("Start TLS >", forState: .Normal)
            default:
                self.transportSecurity.setTitle("Default", forState: .Normal)
            }
        } else {
            self.transportSecurity.setTitle("Default", forState: .Normal)
        }
    }

    @IBAction func alertWithSecurityValues(sender: AnyObject) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Security protocol", comment: ""),
            message: NSLocalizedString("Choose a Security protocol for your accont", comment: ""),
            preferredStyle: .ActionSheet)
        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(CancelAction)
        let StartTLSAction = UIAlertAction(title: "Start TLS", style: .Default) { (action) in
            self.model.transportSmtp = ConnectionTransport.StartTLS
            self.transportSecurity.setTitle("Start TLS >", forState: .Normal)
        }
        alertController.addAction(StartTLSAction)
        let TLSAction = UIAlertAction(title: "TLS", style: .Default) { (action) in
            self.model.transportSmtp = ConnectionTransport.TLS
            self.transportSecurity.setTitle("TLS >", forState: .Normal)
        }
        alertController.addAction(TLSAction)
        let NONEAction = UIAlertAction(title: "Plain", style: .Default) { (action) in
            self.model.transportSmtp = ConnectionTransport.Plain
            self.transportSecurity.setTitle("Plain >", forState: .Normal)
        }
        alertController.addAction(NONEAction)
        self.presentViewController(alertController, animated: true) {}
        model.transportSecuritySMTP = (transportSecurity.titleLabel?.text)!

        updateView()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        mailSettings.serverhostSMTP = serverValue.text!
        let portSMTPAux:String = portValue.text!
        mailSettings.portSMTP = UInt16(portSMTPAux)!

        let connect = ConnectInfo.init(
            email: mailSettings.email!, imapPassword: mailSettings.password!,
            imapServerName: mailSettings.serverhostIMAP!, imapServerPort: mailSettings.portIMAP!,
            imapTransport: model.transportSmtp!, smtpServerName: mailSettings.serverhostSMTP!,
            smtpServerPort: mailSettings.portSMTP!, smtpTransport: model.transportSmtp!)

        let _ = appConfig?.grandOperator.verifyConnection(connect, completionBlock: { (error) in
            GCD.onMain({
                let account = (self.appConfig?.model.insertAccountFromConnectInfo(connect))!
            })
        })
        if segue.identifier == "inboxMail" {
            if let destination = segue.destinationViewController as? EmailListViewController {
            }
        }
    }
}
