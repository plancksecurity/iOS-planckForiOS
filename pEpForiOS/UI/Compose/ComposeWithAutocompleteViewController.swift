//
//  ComposeWithAutocompleteViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class ComposeViewControllerModel {
    var shortMessage: String? = nil
    var to: String? = nil
}

class ComposeWithAutocompleteViewController: UITableViewController {
    /**
     The index of the cell containing the body of the message for the user to write.
     */
    let bodyTextFieldRowNumber = 3

    var appConfig: AppConfig?
    var model = ComposeViewControllerModel.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(tableView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
    }

    // MARK: -- UITableViewDelegate

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return bodyTextFieldRowNumber + 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row < bodyTextFieldRowNumber {
            let cell = tableView.dequeueReusableCellWithIdentifier("RecipientCell", forIndexPath: indexPath) as! RecipientCell
            cell.recipientType = RecipientType.fromRawValue(indexPath.row + 1)
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("MessageBodyCell", forIndexPath: indexPath) as! MessageBodyCell
            cell.bodyTextView.delegate = self
            return cell
        }
    }
}

extension ComposeWithAutocompleteViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        let currentOffset = tableView.contentOffset
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
        tableView.setContentOffset(currentOffset, animated: false)
    }
}