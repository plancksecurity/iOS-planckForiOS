//
//  ComposeWithAutocompleteViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class ComposeWithAutocompleteViewController: UITableViewController {
    struct UIModel {
        enum Mode {
            case Normal
            case Search
        }

        var mode: Mode = .Normal

        var searchSnippet: String? = nil

        /**
         The search table model.
         */
        var contacts: [IContact] = []

        var recipientCell: RecipientCell? = nil
    }

    var model: UIModel = UIModel.init()

    /**
     The index of the cell containing the body of the message for the user to write.
     */
    let bodyTextFieldRowNumber = 3

    var appConfig: AppConfig?

    var longBodyMessageTextView: UITextView? = nil
    var recipientCells: [UITextField:RecipientCell] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(tableView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateContacts() {
        if let snippet = model.searchSnippet {
            if let privateMOC = appConfig?.coreDataUtil.privateContext() {
                privateMOC.performBlock() {
                    let modelBackground = Model.init(context: privateMOC)
                    let contacts = modelBackground.contactsBySnippet(snippet).map() {
                        ContactDAO.init(contact: $0) as IContact
                    }
                    GCD.onMain() {
                        self.model.contacts.removeAll()
                        self.model.contacts.appendContentsOf(contacts)
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    func resetTableViewToNormal() {
        model.searchSnippet = ""
        model.mode = .Normal
        model.contacts = []
        tableView.reloadData()
    }

    // MARK: -- UITableViewDelegate

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if model.mode == UIModel.Mode.Search {
            if let cell = model.recipientCell {
                return cell.bounds.height
            }
        }
        return 0
    }

    override func tableView(tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        if model.mode == UIModel.Mode.Search && section == 0 {
            return model.recipientCell
        }
        return nil
    }

    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView,
                   forSection section: Int) {
        if model.mode == UIModel.Mode.Search && section == 0 {
            model.recipientCell?.recipientTextField.becomeFirstResponder()
        }
    }

    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if model.mode == UIModel.Mode.Search {
            if let cell = model.recipientCell {
                let c = model.contacts[indexPath.row]
                if var text = cell.recipientTextField.text?.finishedRecipientPart() {
                    text += c.email + ", "
                    cell.recipientTextField.text = text
                }
            }
            resetTableViewToNormal()
        }
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
                            forRowAtIndexPath indexPath: NSIndexPath) {
        if model.mode == UIModel.Mode.Normal {
            if let cell = model.recipientCell {
                cell.recipientTextField.becomeFirstResponder()
            }
        }
    }

    // MARK: -- UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if model.mode == UIModel.Mode.Normal {
            return bodyTextFieldRowNumber + 1
        } else {
            return model.contacts.count
        }
    }

    override func tableView(tableView: UITableView,
                            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let recipientCellID = "RecipientCell"
        let messageBodyCellID = "MessageBodyCell"
        let contactTableViewCellID = "ContactTableViewCell"

        if model.mode == UIModel.Mode.Normal {
            // Normal mode
            if indexPath.row < bodyTextFieldRowNumber {
                // Recipient cell
                let cell = tableView.dequeueReusableCellWithIdentifier(
                    recipientCellID, forIndexPath: indexPath) as! RecipientCell
                cell.recipientType = RecipientType.fromRawValue(indexPath.row + 1)
                cell.recipientTextField.delegate = self

                // Cache the cell for later use
                recipientCells[cell.recipientTextField] = cell

                return cell
            } else {
                // Body message cell
                let cell = tableView.dequeueReusableCellWithIdentifier(
                    messageBodyCellID, forIndexPath: indexPath) as! MessageBodyCell
                cell.bodyTextView.delegate = self

                // Store the body text field for later
                longBodyMessageTextView = cell.bodyTextView

                return cell
            }
        } else {
            // Search mode
            let contactIndex = indexPath.row
            let contact = model.contacts[contactIndex]
            let cell = tableView.dequeueReusableCellWithIdentifier(
                contactTableViewCellID, forIndexPath: indexPath) as! ContactTableViewCell
            cell.contact = contact
            return cell
        }
    }
}

// MARK: -- UITextViewDelegate (for body text)

extension ComposeWithAutocompleteViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        if textView == longBodyMessageTextView {
            let currentOffset = tableView.contentOffset
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            tableView.setContentOffset(currentOffset, animated: false)
        }
    }
}

// MARK: -- UITextFieldDelegate (for any recipient text field)

extension ComposeWithAutocompleteViewController: UITextFieldDelegate {
    func textField(textField: UITextField,
                   shouldChangeCharactersInRange range: NSRange,
                                                 replacementString string: String) -> Bool {
        if let cell = recipientCells[textField] {
            if let text = textField.text {
                if string == " " {
                    let newText = text.stringByReplacingCharactersInRange(range, withString: ", ")
                    textField.text = newText
                    return false
                }
                let newText = text.stringByReplacingCharactersInRange(range, withString: string)
                let lastPart = newText.unfinishedRecipientPart()
                if lastPart == "" {
                    resetTableViewToNormal()

                    // For some reason, we have to do that manually.
                    // Maybe the changing of hierarchy (due to the mode change)
                    // interferes with the replacement.
                    textField.text = newText.finishedRecipientPart()
                    return false
                } else {
                    model.searchSnippet = lastPart
                    model.mode = .Search
                    model.contacts = []
                    model.recipientCell = cell
                    updateContacts()
                }
            }
        }
        return true
    }
}