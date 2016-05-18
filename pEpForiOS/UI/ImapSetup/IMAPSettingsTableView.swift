//
//  MyTableIMAPSettings.swift
//  pEpForiOS
//
//  Created by ana on 15/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIAlertController {
    func setupActionFromConnectionTransport(transport: ConnectionTransport,
                                            block: (ConnectionTransport) -> ()) {
        let action = UIAlertAction(title: transport.localizedString(),
                                   style: .Default, handler: { action in
                                    block(transport)
        })
        self.addAction(action)
    }
}

class IMAPSettingsTableView: UITableViewController  {

    @IBOutlet weak var serverValue: UITextField!
    @IBOutlet weak var portValue: UITextField!
    @IBOutlet weak var transportSecurity: UIButton!

    var appConfig: AppConfig!
    var model: ModelUserInfoTable!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        serverValue.becomeFirstResponder()
        updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        serverValue.text = model.serverIMAP
        portValue.text = String(model.portIMAP)

        transportSecurity.setTitle(model.transportIMAP.localizedString(), forState: .Normal)
    }

    @IBAction func alertWithSecurityValues(sender: AnyObject) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Transport protocol",
                comment: "UI alert title for transport protocol"),
            message: NSLocalizedString("Choose a Security protocol for your accont",
                comment: "UI alert message for transport protocol"),
            preferredStyle: .ActionSheet)

        let block: (ConnectionTransport) -> () = { transport in
            self.model.transportIMAP = transport
            self.updateView()
        }

        alertController.setupActionFromConnectionTransport(.Plain, block: block)
        alertController.setupActionFromConnectionTransport(.TLS, block: block)
        alertController.setupActionFromConnectionTransport(.StartTLS, block: block)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel for an alert view"),
            style: .Cancel) { (action) in}
        alertController.addAction(cancelAction)
        self.presentViewController(alertController, animated: true) {}
    }

    @IBAction func changePort(sender: UITextField) {
        if let text = portValue.text {
            if let port = UInt16(text) {
                model.portIMAP = port
            }
        }
    }

    @IBAction func changeServer(sender: UITextField) {
        model.serverIMAP = serverValue.text!
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SMTPSettings" {
            if let destination = segue.destinationViewController as? SMTPSettingsTableView {
                destination.appConfig = self.appConfig
                destination.model = self.model
            }
        }
    }
}
