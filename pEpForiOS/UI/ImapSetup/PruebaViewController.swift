//
//  PruebaViewController.swift
//  pEpForiOS
//
//  Created by ana on 17/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class PruebaViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var autocompleteTableView: UITableView!
    @IBOutlet weak var toUIView: UIView!
    @IBOutlet weak var forUIView: UIView!
    @IBOutlet weak var ccUIView: UIView!
    @IBOutlet weak var bccUIView: UIView!
    @IBOutlet weak var subjectUIView: UIView!

    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var forTextField: UITextField!
    @IBOutlet weak var ccTextField: UITextField!
    @IBOutlet weak var bccTextField: UITextField!
    @IBOutlet weak var subjectTextField: UITextField!

    @IBOutlet weak var longMessageTextView: UITextView!

     var appConfig: AppConfig?
    //let addressBook  = AddressBook.init()
    //var systemContacts:[IContact]!
    var dummyContact = ["Ana","Huss","Yolanda","Misifu"]

    override func viewDidLoad() {
        super.viewDidLoad()
        autocompleteTableView.delegate = self
        autocompleteTableView.dataSource = self
        autocompleteTableView.hidden = true
        autocompleteTableView.layer.zPosition = 1
        forUIView.layer.zPosition = 0
        ccUIView.layer.zPosition = 0
        bccUIView.layer.zPosition  = 0
        subjectUIView.layer.zPosition = 0

        /*if addressBook.authorizationStatus == .NotDetermined {
            addressBook.authorize()
        }*/
        print(autocompleteTableView.frame.width)

        //let constraint = autocompleteTableView.autoMatchDimension(.Height, toDimension: .Width, ofView: tallView)
    }

    func generalAutocompletion(yPosition: CGFloat) {
        let location = CGPoint(x: toUIView.frame.origin.x,y:yPosition)
        autocompleteTableView.frame.origin = location
        autocompleteTableView.hidden = false

    }

    @IBAction func autocompleteToField(sender: UITextField) {

        let yposition = toUIView.frame.size.height + toUIView.frame.origin.y

        autocompleteTableView.frame = CGRectMake(autocompleteTableView.frame.origin.x, autocompleteTableView.frame.origin.y,toUIView.frame.width, autocompleteTableView.frame.size.height);

        //generalAutocompletion(yposition)
        //systemContacts = self.addressBook.contactsBySnippet(sender.text!)
    }

    @IBAction func autocompleteForField(sender: UITextField) {
        let yposition = (toUIView.frame.size.height * 2) + toUIView.frame.origin.y
        generalAutocompletion(yposition)
    }

    @IBAction func autocompleteCcField(sender: UITextField) {
        let yposition = (toUIView.frame.size.height * 3) + toUIView.frame.origin.y
        generalAutocompletion(yposition)
    }

    @IBAction func autocompleteBccField(sender: UITextField) {
        let yposition = (toUIView.frame.size.height * 4) + toUIView.frame.origin.y
        generalAutocompletion(yposition)
    }

    @IBAction func resetAutocomplete(sender: UITextField) {
        autocompleteTableView.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //posibleMatchingContacts = ["Para","Ana","Rebollo"]
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        //cell.textLabel?.text = systemContacts[indexPath.row].name
        //cell.textLabel?.text = dummyContact[indexPath.row]
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        autocompleteTableView.hidden = true
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
            let to = appConfig?.model.insertOrUpdateContactEmail(toContact, name: nil,
                                                                 addressBookID: nil) as! Contact
            msg.addToObject(to)
        }
        for ccContact in ccContactsSeparated {
            let cc = appConfig?.model.insertOrUpdateContactEmail(ccContact, name: nil,
                addressBookID: nil) as! Contact
            msg.addCcObject(cc)
        }
        for bccContact in bccContactsSeparated {
            let bbc = appConfig?.model.insertOrUpdateContactEmail(
                bccContact, name: nil, addressBookID: nil) as! Contact
            msg.addBccObject(bbc)
        }
        return msg
    }

    @IBAction func sendEmail(sender: UIBarButtonItem) {
        let subject = subjectTextField.text!
        let longMessage = longMessageTextView.text!
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

}
