//
//  ComposeWithAutocompleteViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class ComposeViewControllerModel {
    var shortMessage: String?
    var to: String?
}

class ComposeWithAutocompleteViewController: UITableViewController {

    var appConfig: AppConfig?
    var model: ComposeViewControllerModel?

    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var ccTextField: UITextField!
    @IBOutlet weak var bccTextField: UITextField!
    @IBOutlet weak var shortMessageTextField: UITextField!
    @IBOutlet weak var longMessageTextField: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func showErrorMessage (message: String) {
        let alertView = UIAlertController(
            title: NSLocalizedString("Error",
                comment: "the text in the title for the error message AlerView when sending an email crashes"),
            message:message, preferredStyle: .Alert)

        alertView.addAction(UIAlertAction(title: NSLocalizedString("Ok",
            comment: "confirmation button text for error message AlertView when sending an email crashes"),
            style: .Default, handler: nil))
        presentViewController(alertView, animated: true, completion: nil)
    }

    func createMail(subject: String,
                    longMessage: String,
                    toContactsSeparated: [String],
                    ccContactsSeparated: [String],
                    bccContactsSeparated: [String]) -> Message {

        let msg = appConfig?.model.insertNewMessage() as! Message
        msg.subject = subject
        msg.longMessage = longMessage
        for toContact in toContactsSeparated {
            let to = appConfig?.model.insertOrUpdateContactEmail(toContact, name: nil) as! Contact
            msg.addToObject(to)
        }
        for ccContact in ccContactsSeparated {
            let cc = appConfig?.model.insertOrUpdateContactEmail(ccContact, name: nil) as! Contact
            msg.addCcObject(cc)
        }
        for bccContact in bccContactsSeparated {
            let bbc = appConfig?.model.insertOrUpdateContactEmail(
                bccContact, name: nil) as! Contact
            msg.addBccObject(bbc)
        }
        return msg
    }

    @IBAction func sendEmail(sender: AnyObject) {
        let subject = shortMessageTextField.text!
        let longMessage = longMessageTextField.text!
        let toContactsSeparated = toTextField.text!.componentsSeparatedByString(";")
        let ccContactsSeparated = ccTextField.text!.componentsSeparatedByString(";")
        let bccContactsSeparated = bccTextField.text!.componentsSeparatedByString(";")

        let message = createMail(subject,
                                 longMessage: longMessage,
                                 toContactsSeparated: toContactsSeparated,
                                 ccContactsSeparated: ccContactsSeparated,
                                 bccContactsSeparated: bccContactsSeparated)

        if let account = appConfig?.model.fetchLastAccount() as? Account {
            appConfig?.grandOperator.sendMail(message, account:account, completionBlock: { (error) in
                if error != nil {
                    GCD.onMain() {
                        self.showErrorMessage(NSLocalizedString("Could not send the message", comment: ""))
                    }
                }
            })
        }
    }

    func updateView() {
        if let subject = model!.shortMessage {
            shortMessageTextField.text = subject
        }
        if let to = model!.to {
            toTextField.text = to
        }
    }
}