//
//  EmailViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit



class EmailViewController: UITableViewController {

    struct UIState {
        var loadingMail: Bool = false
    }

    @IBOutlet weak var toStackView: UIStackView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var contentWebView: UIWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let state = UIState()
    var appConfig: AppConfig!
    var message: Message!
    var model: ComposeViewControllerModel = ComposeViewControllerModel()

    @IBOutlet weak var To: UITableViewCell!
    @IBOutlet weak var For: UITableViewCell!
    @IBOutlet weak var date: UITableViewCell!
    @IBOutlet weak var tittle: UITableViewCell!
    @IBOutlet weak var messageContent: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
    }

    func updateView() {
        let contacto:Contact = message.to.firstObject as! Contact
        print("to:")
        print(contacto.name)
        /*for contact in message.to {
         print(contact)
         }*/

        For.textLabel?.text = message.from?.name

        if let dateMessage = message.originationDate {
            date.textLabel?.text = String(dateMessage)
        }
        tittle.textLabel?.text = message.subject
        print("long message:")
        print(message.longMessage)
        messageContent.textLabel?.text = message.longMessage
    }

    @IBAction func pressReply(sender: UIBarButtonItem) {


        let alertViewWithoutTittle = UIAlertController()
        let alertActionReply = UIAlertAction (title: NSLocalizedString("Reply",
            comment: "Reply button text for reply action in AlertView in the screen with the message details"), style: .Default) { (action) in
                //self.model.shortMessage = self.message.subject
                if let subject = self.message.subject {
                    self.model.shortMessage = subject
                }
                if let For = self.message.from?.name {
                   self.model.to = For
                }
                self.performSegueWithIdentifier("replySegue" , sender: self)
        }
        alertViewWithoutTittle.addAction(alertActionReply)

        let alertActionReplyAll = UIAlertAction (title: NSLocalizedString("Reply All",
            comment: "Reply all button text for reply all action in AlertView in the screen with the message details"), style: .Default) { (action) in}
        alertViewWithoutTittle.addAction(alertActionReplyAll)

        let alertActionForward = UIAlertAction (title: NSLocalizedString("Forward",
            comment: "Forward button text for forward action in AlertView in the screen with the message details"), style: .Default) { (action) in}
        alertViewWithoutTittle.addAction(alertActionForward)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel button text for cancel action in AlertView in the screen with the message details"),
            style: .Cancel) { (action) in}

        alertViewWithoutTittle.addAction(cancelAction)

        presentViewController(alertViewWithoutTittle, animated: true, completion: nil)
    }

    /*override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "replySegue") {
            let destination = segue.destinationViewController as? ComposeWithAutocompleteViewController;
            destination!.model = model
        }
    }*/

}
