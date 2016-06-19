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
        var loadingMail = false
    }

    enum TableViewCells: Int {
        case From = 0
        case Recipients
        case Subject
        case Body
        case Last

        func cellId() -> String? {
            switch self {
            case .Recipients:
                return "RecipientsCell"
            default:
                return nil
            }
        }
    }

    let state = UIState()
    var appConfig: AppConfig!
    var message: Message!
    var model: ComposeViewControllerModel = ComposeViewControllerModel()
    let dateFormatter = UIHelper.dateFormatterEmailDetails()

    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(self.tableView)
        updateView()
    }

    func updateView() {
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

    // MARK: UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableViewCells.Last.rawValue - 1
    }

    override func tableView(tableView: UITableView,
                            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let kNormalCell = "NormalCell"
        let kRecipientCell = "RecipientCell"

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kNormalCell)

        if indexPath.row == TableViewCells.Recipients.rawValue {
            let cell = tableView.dequeueReusableCellWithIdentifier(
                kRecipientCell, forIndexPath: indexPath) as? RecipientViewCellTableViewCell
            cell?.message = message
            return cell!
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(kNormalCell,
                                                                   forIndexPath: indexPath)
            return cell
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView,
                            estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 44.0
    }

    override func tableView(tableView: UITableView,
                   heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if let rv = cell as? RecipientViewCellTableViewCell {
                return rv.intrinsicContentSize().height
            }
        }
        return 44.0
    }
}