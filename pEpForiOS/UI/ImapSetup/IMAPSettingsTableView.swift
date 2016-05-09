//
//  MyTableIMAPSettings.swift
//  pEpForiOS
//
//  Created by ana on 15/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public struct ModelIMAPSettingsInfoTable {

    public var IMAPServer:String = "default.imap.server"
    public var IMAPPort:UInt16 = 993
    public var transportSecurityIMAP:String = "NONE"

    public init(IMAPServer:String,IMAPPort:UInt16,transportSecurityIMAP:String) {
        self.IMAPServer = IMAPServer
        self.IMAPPort = IMAPPort
        self.transportSecurityIMAP = transportSecurityIMAP
    }
}

class IMAPSettingsTableView: UITableViewController  {

    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    var appConfig: AppConfig?
    var mailSettings = MailSettingParameters()
    var model = ModelIMAPSettingsInfoTable(IMAPServer:"default.imap.server",IMAPPort: 993,transportSecurityIMAP: "NONE")

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func textFieldDoneEditing(sender: AnyObject) {
        sender.resignFirstResponder()
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
        model.transportSecurityIMAP = (transportSecurity.titleLabel?.text)!
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SMTPSettings" {
            mailSettings.serverhostIMAP = serverValue.text!
            mailSettings.transportSecurityIMAP = model.transportSecurityIMAP
            let aux:String = portValue.text!
            mailSettings.portIMAP = UInt16(aux)!
            if let destination = segue.destinationViewController as? SMTPSettingsTableView {
                destination.mailSettings = mailSettings
                destination.appConfig = appConfig
            }
        }
    }
}
