//
//  MyTableIMAPSettings.swift
//  pEpForiOS
//
//  Created by ana on 15/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public struct ModelIMAPSettingsInfoTable {

    public var IMAPServer: String?
    public var IMAPPort: UInt16?
    public var transportIMAP: ConnectionTransport?
}

class IMAPSettingsTableView: UITableViewController  {

    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    var appConfig: AppConfig?
    var mailSettings = MailSettingParameters()
    var model = ModelIMAPSettingsInfoTable()

    override func viewDidLoad() {
        super.viewDidLoad()
        serverValue.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        if let transport = model.transportIMAP {
            switch transport {
            case .StartTLS:
                self.transportSecurity.setTitle("Start TLS >", forState: .Normal)
            case .Plain:
                self.transportSecurity.setTitle("Plain >", forState: .Normal)
            default:
                self.transportSecurity.setTitle("TLS", forState: .Normal)
                self.transportSecurity.backgroundColor?.CGColor
            }
        } else {
            self.transportSecurity.setTitle("Plain", forState: .Normal)
        }
    }

    @IBAction func alertWithSecurityValues(sender: AnyObject) {
        let alertController = UIAlertController(title: "Security protocol", message: "Choose a Security protocol for your accont", preferredStyle: .ActionSheet)

        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in}
        alertController.addAction(CancelAction)

        let StartTLSAction = UIAlertAction(title: "Start TLS", style: .Default) { (action) in
            self.transportSecurity.setTitle("Start TLS >", forState: .Normal)
            self.model.transportIMAP = ConnectionTransport.StartTLS
            self.updateView()
        }
        alertController.addAction(StartTLSAction)
        let TLSAction = UIAlertAction(title: "TLS", style: .Default) { (action) in
            self.transportSecurity.setTitle("TLS >", forState: .Normal)
            self.model.transportIMAP = ConnectionTransport.TLS
            self.updateView()
        }
        alertController.addAction(TLSAction)
        let NONEAction = UIAlertAction(title: "Plain", style: .Default) { (action) in
            self.transportSecurity.setTitle("Plain >", forState: .Normal)
            self.model.transportIMAP = ConnectionTransport.Plain
            self.updateView()
        }
        alertController.addAction(NONEAction)
        self.presentViewController(alertController, animated: true) {}
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SMTPSettings" {
            mailSettings.serverhostIMAP = serverValue.text!
            mailSettings.transportSecurityIMAP = model.transportIMAP
            if let aux = portValue.text {
                mailSettings.portIMAP = UInt16(aux)!
                if let destination = segue.destinationViewController as? SMTPSettingsTableView {
                    destination.mailSettings = mailSettings
                    destination.appConfig = appConfig
                }
            }
        }
    }
}
