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
    @IBOutlet weak var ccoTextField: UITextField!
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

    func createMail() -> Message {
        let msg = appConfig?.model.insertNewMessage() as! Message
        msg.subject = shortMessageTextField.text!
        msg.longMessage = longMessageTextField.text!
        /*let from = appConfig?.model.insertOrUpdateContactEmail(
            "test001@peptest.ch", name: nil) as! Contact*/
        //msg.from = from
        let to = appConfig?.model.insertOrUpdateContactEmail(
            toTextField.text!, name: nil) as! Contact
        msg.addToObject(to)
        let cc = appConfig?.model.insertOrUpdateContactEmail(
            ccTextField.text!, name: nil) as! Contact
        msg.addCcObject(cc)
        let bbc = appConfig?.model.insertOrUpdateContactEmail(
            ccoTextField.text!, name: nil) as! Contact
        msg.addBccObject(bbc)
        return msg
    }

    @IBAction func sendEmail(sender: AnyObject) {
        let message = createMail()

        print("MESSAGE SUBJECT \(message.subject)\n")
        print("MESSAGE LONG MESSAGE")
        print(message.longMessage)
        print("MESSAGE TO")
        print(message.to)
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