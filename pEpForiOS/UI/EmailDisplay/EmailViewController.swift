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

    let state = UIState()
    var appConfig: AppConfig!
    var message: Message!
    var model: ComposeViewControllerModel = ComposeViewControllerModel()
    let dateFormatter = UIHelper.dateFormatterEmailDetails()

    @IBOutlet weak var toCell: UITableViewCell!
    @IBOutlet weak var fromCell: UITableViewCell!
    @IBOutlet weak var dateCell: UITableViewCell!
    @IBOutlet weak var titleCell: UITableViewCell!
    @IBOutlet weak var messageContentCell: UITableViewCell!
    @IBOutlet weak var toLabelContainer: LabelContainerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
    }

    func updateView() {
        updateLabelContainer(toLabelContainer, contacts: message.to)
        fromCell.textLabel?.text = message.from?.displayString()

        if let dateMessage = message.originationDate {
            UIHelper.putString(dateFormatter.stringFromDate(dateMessage),
                               toLabel: dateCell.textLabel)
        }
        titleCell.textLabel?.text = message.subject
        messageContentCell.textLabel?.text = message.longMessage
    }

    func updateLabelContainer(container: LabelContainerView, contacts: NSOrderedSet) {
        var labels: [UILabel] = []
        for contact in contacts {
            if let c = contact as? Contact {
                let label = UILabel.init()
                label.text = c.displayString()
                labels.append(label)
            }
        }
        container.labels = labels
    }

    @IBAction func pressReply(sender: UIBarButtonItem) {
        let alertViewWithoutTittle = UIAlertController()
        let alertActionReply = UIAlertAction (title: NSLocalizedString("Reply",
            comment: "Reply button text for reply action in AlertView in the screen with the message details"),
                                              style: .Default) { (action) in
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

        let alertActionReplyAll = UIAlertAction(
            title: NSLocalizedString("Reply All",
                comment: "Reply all button text for reply all action in AlertView in the screen with the message details"),
            style: .Default) { (action) in }
        alertViewWithoutTittle.addAction(alertActionReplyAll)

        let alertActionForward = UIAlertAction(
            title: NSLocalizedString("Forward",
                comment: "Forward button text for forward action in AlertView in the screen with the message details"),
            style: .Default) { (action) in }
        alertViewWithoutTittle.addAction(alertActionForward)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel",
                comment: "Cancel button text for cancel action in AlertView in the screen with the message details"),
            style: .Cancel) { (action) in }

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
