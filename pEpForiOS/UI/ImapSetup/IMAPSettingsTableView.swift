//
//  MyTableIMAPSettings.swift
//  pEpForiOS
//
//  Created by ana on 15/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class IMAPSettingsTableView: UITableViewController  {

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

    @IBAction func textFieldDoneEditing(sender: AnyObject) {
        sender.resignFirstResponder()
    }

    @IBAction func alertWithSecurityValues(sender: AnyObject) {
        let alertController = UIAlertController(title: "Security protocol", message: "Choose an Security protocol  for your accont", preferredStyle: .ActionSheet)
        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in}
        alertController.addAction(CancelAction)
        let StartTLSAction = UIAlertAction(title: "Start TLS", style: .Default) { (action) in}
        alertController.addAction(StartTLSAction)
        let TLSAction = UIAlertAction(title: "TLS", style: .Default) { (action) in}
        alertController.addAction(TLSAction)
        let NONEAction = UIAlertAction(title: "Plain", style: .Default) { (action) in}
        alertController.addAction(NONEAction)
        self.presentViewController(alertController, animated: true) {}
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SMTPSettings" {
            mailSettings.serverhostIMAP = serverValue.text!
            let aux:String = portValue.text!
            mailSettings.portIMAP = UInt16(aux)!
            if let destination = segue.destinationViewController as? SMTPSettingsTableView {
                destination.mailSettings = mailSettings
                destination.appConfig = appConfig
            }
        }
    }
}
