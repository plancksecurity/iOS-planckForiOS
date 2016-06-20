//
//  EmailViewController.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class EmailViewController: UIViewController {
    let segueReply = "segueReply"

    struct UIState {
        var loadingMail = false
    }

    let state = UIState()
    var appConfig: AppConfig!
    let headerView = EmailHeaderView.init()

    var message: Message!

    var model: ComposeViewControllerModel = ComposeViewControllerModel()
    let dateFormatter = UIHelper.dateFormatterEmailDetails()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(headerView)
    }

    func update() {
        headerView.message = message
        headerView.update(view.bounds.size.width)
        headerView.frame.size = headerView.preferredSize

        if let navFrame = navigationController?.navigationBar.frame {
            // Offset the view by navigation bar
            headerView.frame.origin.y += navFrame.origin.y + navFrame.size.height
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        update()
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
                self.performSegueWithIdentifier(self.segueReply , sender: self)
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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == segueReply) {
            let destination = segue.destinationViewController
                as? ComposeWithAutocompleteViewController;
            destination!.model = model
        }
    }
}