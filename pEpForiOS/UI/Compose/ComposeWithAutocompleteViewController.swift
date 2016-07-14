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

    let newline = "\n"
    let justComma = ","
    let commaWithSpace: String

    @IBOutlet weak var sendButton: UIBarButtonItem!

    /**
     The index of the cell containing the body of the message for the user to write.
     */
    let bodyTextFieldRowNumber = 3

    var appConfig: AppConfig?

    var longBodyMessageTextView: UITextView? = nil

    /**
     The recipient cells, mapped by their text field for fast access.
     */
    var recipientCellsByTextField = [UITextField: RecipientCell]()

    /**
     The recipient cells, mapped by their index row.
     */
    var recipientCells = [Int: RecipientCell]()

    required init?(coder aDecoder: NSCoder) {
        commaWithSpace = "\(justComma) "
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(tableView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateSendButtonFromView()
    }

    func updateContacts() {
        if let snippet = model.searchSnippet {
            if let privateMOC = appConfig?.coreDataUtil.privateContext() {
                privateMOC.performBlock() {
                    let modelBackground = Model.init(context: privateMOC)
                    let contacts = modelBackground.contactsBySnippet(snippet).map() {
                        AddressbookContact.init(contact: $0) as IContact
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

    /**
     Checks all recipient fields for validity, and updates the Send button accordingly.
     */
    func updateSendButtonFromView() {
        var allEmpty = true
        var allCorrect = true
        for (_, cell) in recipientCells {
            let tf = cell.recipientTextField
            if let text = tf.text {
                if text != "" {
                    allEmpty = false
                    let trailingRemoved = text.removeTrailingPattern("\(justComma)\\s*")
                    if !trailingRemoved.isProbablyValidEmailListSeparatedBy(justComma) {
                        allCorrect = false
                    }
                }
            }
        }
        sendButton.enabled = !allEmpty && allCorrect
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
            // We are reusing an ordinary cell as a header, this might lead to:
            // "no index path for table cell being reused".
            // Can probably ignored.
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
                    if text != "" && !text.matchesPattern(",\\s*$") {
                        text += ", "
                    }
                    text += c.email + ", "
                    cell.recipientTextField.text = text
                }
            }
            updateSendButtonFromView()
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
                recipientCellsByTextField[cell.recipientTextField] = cell
                recipientCells[indexPath.row] = cell

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
    func isFreshlyEnteredTextProbablyEmail(oldText: String, newText: String,
                                           delimiter: String) -> Bool {
        return newText != "\(delimiter) " && !oldText.matchesPattern("\(delimiter) $") &&
            newText.removeTrailingPattern(
                "\(delimiter)\\s*").isProbablyValidEmailListSeparatedBy(delimiter)
    }

    /**
     Gets the identity colors of all emails in a given String, and sets the text field's
     `attributedText` attribute correspondingly.
     */
    func colorEmailTextField(textField: UITextField, emailString: String, delimiter: String) {
        if let context = appConfig?.coreDataUtil.privateContext() {
            context.performBlock() {
                let emails = emailString.componentsSeparatedByString(
                    delimiter).map({$0.trimmedWhiteSpace()})
            }
        }
    }

    func textField(textField: UITextField,
                   shouldChangeCharactersInRange range: NSRange,
                                                 replacementString string: String) -> Bool {
        if let cell = recipientCellsByTextField[textField] {
            if let text = textField.text {
                if string == " " {
                    let newText = text.stringByReplacingCharactersInRange(
                        range, withString: commaWithSpace)
                    if isFreshlyEnteredTextProbablyEmail(
                        text, newText: newText, delimiter: justComma) {
                        textField.text = newText
                        resetTableViewToNormal()
                    }
                    updateSendButtonFromView()
                    return false
                }
                if string == newline {
                    if isFreshlyEnteredTextProbablyEmail(
                        text, newText: text, delimiter: justComma) {
                        resetTableViewToNormal()
                    }
                    updateSendButtonFromView()
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
                    updateSendButtonFromView()
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
        updateSendButtonFromView()
        return true
    }
}