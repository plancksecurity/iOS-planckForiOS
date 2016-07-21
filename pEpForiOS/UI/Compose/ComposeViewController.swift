//
//  ComposeViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

class ComposeViewController: UITableViewController {
    struct UIModel {
        enum Mode {
            case Normal
            case Search
        }

        var tableMode: Mode = .Normal

        var searchSnippet: String? = nil

        /**
         The search table model.
         */
        var contacts: [IContact] = []

        /**
         The recipient cell that is currently used for contact completion.
         */
        var recipientCell: RecipientCell? = nil

        /**
         Is there network activity (e.g., sending the mail?)
         */
        var networkActivity = false
    }

    var model: UIModel = UIModel.init()

    let comp = "ComposeViewController"

    let unwindToEmailListMailSentSegue = "unwindToEmailListMailSentSegue"

    /** Constant that is used for checking user input on recipient text fields */
    let newline = "\n"

    /** Constant for string delimiter in recipient email addresses */
    let recipientStringDelimiter = ","

    /**
     When the user is editing recipients and presses <SPACE>, this text is entered instead.
     */
    let delimiterWithSpace: String

    /**
     The message to appear in the body text when it's empty.
     */
    let emptyBodyTextMessage: String

    @IBOutlet weak var sendButton: UIBarButtonItem!

    /**
     The row number of the cell containing the body of the message for the user to write.
     */
    let subjectRowNumber = 3

    /**
     The row number of the cell containing the subject of the message.
     */
    let bodyTextRowNumber = 4

    var appConfig: AppConfig?

    /**
     A reference to the long body text view, contained in a table view cell.
     */
    var longBodyMessageTextView: UITextView? = nil

    /**
     A reference to the subject text field.
     */
    var subjectTextField: UITextField? = nil

    /**
     The recipient cells, mapped by their text field for fast access.
     */
    var recipientCellsByTextField = [UITextField: RecipientCell]()

    /**
     The recipient cells, mapped by their index row.
     */
    var recipientCells = [Int: RecipientCell]()

    /**
     Always cache the operation for the latest color check, so we don't overtaxt the system.
     */
    var currentOutgoingRatingOperation: OutgoingMessageColorOperation?

    /**
     The message we're constructing
     */
    var messageToSend: IMessage?

    /**
     For determining if we give the focus to the to text field.
     */
    var firstTimeToCellWasCreated = false

    /**
     For showing sending mail activity.
     */
    lazy var activityIndicator = UIActivityIndicatorView.init(activityIndicatorStyle: .Gray)

    /**
     This originally contains the send button. We need that when exchanging the send
     button for the activity indicator.
     */
    var originalRightBarButtonItem: UIBarButtonItem?

    required init?(coder aDecoder: NSCoder) {
        delimiterWithSpace = "\(recipientStringDelimiter) "
        emptyBodyTextMessage = NSLocalizedString(
            "Enter text here",
            comment: "Placeholder text for where the user should enter the email body text")
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
        updateViewFromRecipients()
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
        model.tableMode = .Normal
        model.contacts = []
        tableView.reloadData()
    }

    /**
     Checks all recipient fields for validity, and updates the Send button accordingly.
     - Returns: A Bool whether the send button was enabled or not.
     */
    func updateSendButtonFromView() -> Bool {
        var allEmpty = true
        var allCorrect = true
        for (_, cell) in recipientCells {
            let tf = cell.recipientTextField
            if let text = tf.text {
                if text != "" {
                    allEmpty = false
                    let trailingRemoved = text.removeTrailingPattern("\(recipientStringDelimiter)\\s*")
                    if !trailingRemoved.isProbablyValidEmailListSeparatedBy(recipientStringDelimiter) {
                        allCorrect = false
                    }
                }
            }
        }
        sendButton.enabled = !allEmpty && allCorrect
        return sendButton.enabled
    }

    /**
     Whenever one of the recipients field changes, call this to validate them,
     update colors, etc.
     */
    func updateViewFromRecipients() {
        // Checking mail color only makes sense if you can actually send that mail,
        // hence the if.
        if updateSendButtonFromView() {
            if let op = currentOutgoingRatingOperation {
                // We have an existing op, let's check it it's still running and
                // don't do anything in that case.
                if op.executing {
                    op.cancel()
                    Log.warnComponent(comp, "Won't check outgoing color, already one in operation")
                    return
                }
            }
            let op = OutgoingMessageColorOperation()
            op.pepMail = pepMailFromViewForCheckingRating()
            op.completionBlock = {
                if !op.cancelled {
                    if let pepColor = op.pepColor {
                        let color = PEPUtil.abstractPepColorFromPepColor(pepColor)
                        GCD.onMain() {
                            var image: UIImage?
                            if let uiColor = UIHelper.sendButtonBackgroundColorFromPepColor(
                                color) {
                                image = UIHelper.imageFromColor(uiColor)
                            }
                            self.sendButton.setBackgroundImage(image, forState: .Normal,
                                barMetrics: UIBarMetrics.Default)
                        }
                    } else {
                        Log.warnComponent(self.comp, "Could not get outgoing message color")
                    }
                }
            }
            op.start()
        }
    }

    /**
     If there is network activity, show it.
     */
    func updateNetworkActivity() {
        if model.networkActivity {
            if originalRightBarButtonItem == nil {
                // save the origignal
                originalRightBarButtonItem = navigationItem.rightBarButtonItem
            }
            activityIndicator.startAnimating()
            let barButtonWithActivity = UIBarButtonItem.init(customView: activityIndicator)
            navigationItem.rightBarButtonItem = barButtonWithActivity
        } else {
            // restore the original
            navigationItem.rightBarButtonItem = originalRightBarButtonItem
            activityIndicator.stopAnimating()
        }
    }

    /**
     Builds a pEp mail dictionary from all the related views. This is just a quick
     method for checking the pEp color rating, it's not exhaustive!
     */
    func pepMailFromViewForCheckingRating() -> PEPMail {
        var message = PEPMail()
        for (_, cell) in recipientCells {
            let tf = cell.recipientTextField
            if let text = tf.text {
                if text != "" {
                    let mailStrings1 = text.componentsSeparatedByString(recipientStringDelimiter).map() {
                        $0.trimmedWhiteSpace()
                    }
                    let mailStrings2 = mailStrings1.filter() {
                        $0 != ""
                    }
                    let model = appConfig?.model
                    let contacts: [PEPContact] = mailStrings2.map() {
                        if let c = model?.contactByEmail($0) {
                            return PEPUtil.pepContact(c)
                        }
                        return PEPUtil.pepContactFromEmail($0, name: $0.namePartOfEmail())
                    }
                    if contacts.count > 0 {
                        var pepKey: String? = nil
                        switch cell.recipientType {
                        case .To:
                            pepKey = kPepTo
                        case .CC:
                            pepKey = kPepCC
                        case .BCC:
                            pepKey = kPepBCC
                        }
                        if let key = pepKey {
                            message[key] = contacts
                        }
                    }
                }
            }
        }
        if let account = appConfig?.currentAccount {
            message[kPepFrom] = PEPUtil.pepContactFromEmail(
                account.email, name: account.nameOfTheUser)
        }
        if let subjectText = subjectTextField?.text {
            message[kPepShortMessage] = subjectText
        }
        if let bodyText = longBodyMessageTextView?.text {
            message[kPepLongMessage] = bodyText
        }
        message[kPepOutgoing] = true
        return message
    }

    func populateMessageWithViewData(message: IMessage, account: IAccount,
                                     model: IModel) -> IMessage {
        // Make a "copy", which really should be the same reference
        var msg = message

        // reset
        msg.to = []
        msg.cc = []
        msg.bcc = []

        msg.subject = nil
        msg.longMessage = nil
        msg.longMessageFormatted = nil

        msg.references = []

        // from
        msg.from = model.insertOrUpdateContactEmail(account.email, name: account.nameOfTheUser)
            as? Contact

        // recipients
        for (_, cell) in recipientCells {
            let tf = cell.recipientTextField
            if let text = tf.text {
                if text != "" {
                    let mailStrings1 = text.componentsSeparatedByString(recipientStringDelimiter).map() {
                        $0.trimmedWhiteSpace()
                    }
                    let mailStrings2 = mailStrings1.filter() {
                        $0 != ""
                    }
                    let contacts: [IContact] = mailStrings2.map() {
                        let c = model.insertOrUpdateContactEmail($0, name: nil)
                        return c
                    }
                    if contacts.count > 0 {
                        let set = NSOrderedSet.init(array: contacts.map() {$0 as AnyObject})
                        switch cell.recipientType {
                        case .To:
                            msg.to = set
                        case .CC:
                            msg.cc = set
                        case .BCC:
                            msg.bcc = set
                        }
                    }
                }
            }
        }

        if let subjectText = subjectTextField?.text {
            msg.subject = subjectText
        }

        if let bodyText = longBodyMessageTextView?.text {
            msg.longMessage = bodyText
        }

        // So far, we don't have references. Once we add reply, we will have.

        return msg
    }

    // MARK: -- Actions

    @IBAction func sendButtonTapped(sender: UIBarButtonItem) {
        guard let appC = appConfig else {
            Log.warnComponent(comp, "Really need a non-nil appConfig")
            return
        }
        guard let account = appC.currentAccount else {
            Log.warnComponent(comp, "Really need a non-nil currentAccount")
            return
        }

        if messageToSend == nil {
            messageToSend = appConfig?.model.insertNewMessageForSendingFromAccountEmail(
                account.email)
        }

        guard let m = messageToSend else {
            Log.warnComponent(comp, "Really need a non-nil messageToSend")
            return
        }

        let msg = populateMessageWithViewData(m, account: account, model: appC.model)

        model.networkActivity = true
        updateNetworkActivity()

        appC.grandOperator.sendMail(
            msg, account: account as! Account, completionBlock: { error in
                if let e = error {
                    Log.errorComponent(self.comp, error: e)
                    // show error
                    GCD.onMain() {
                        self.model.networkActivity = false
                        self.updateNetworkActivity()

                        let alert = UIAlertController.init(
                            title: NSLocalizedString("Error sending message",
                                comment: "Title for the 'Error sending mail' dialog"),
                            message: e.localizedDescription,
                            preferredStyle: .Alert)
                        let okAction = UIAlertAction.init(
                            title: NSLocalizedString("Ok", comment: "Confirm mail sending error"),
                            style: .Default, handler: nil)
                        alert.addAction(okAction)
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                    // dismiss the whole controller?
                    GCD.onMain() {
                        self.model.networkActivity = false
                        self.updateNetworkActivity()
                        self.performSegueWithIdentifier(self.unwindToEmailListMailSentSegue,
                            sender: sender)
                    }
                }
        })
    }

    // MARK: -- UITableViewDelegate

    override func tableView(tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        if model.tableMode == UIModel.Mode.Search {
            if let cell = model.recipientCell {
                return cell.bounds.height
            }
        }
        return 0
    }

    override func tableView(tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        if model.tableMode == UIModel.Mode.Search && section == 0 {
            // We are reusing an ordinary cell as a header, this might lead to:
            // "no index path for table cell being reused".
            // Can probably ignored.
            return model.recipientCell
        }
        return nil
    }

    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView,
                   forSection section: Int) {
        if model.tableMode == UIModel.Mode.Search && section == 0 {
            model.recipientCell?.recipientTextField.becomeFirstResponder()
        }
    }

    override func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if model.tableMode == UIModel.Mode.Search {
            if let cell = model.recipientCell {
                let c = model.contacts[indexPath.row]
                if var text = cell.recipientTextField.text?.finishedRecipientPart() {
                    if text != "" && !text.matchesPattern(",\\s*$") {
                        text += ", "
                    }
                    text += c.email + ", "
                    cell.recipientTextField.text = text
                    colorReceiverTextField(cell.recipientTextField)
                }
            }
            updateViewFromRecipients()
            resetTableViewToNormal()
        }
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
                            forRowAtIndexPath indexPath: NSIndexPath) {
        if model.tableMode == UIModel.Mode.Normal {
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
        if model.tableMode == UIModel.Mode.Normal {
            return bodyTextRowNumber + 1
        } else {
            return model.contacts.count
        }
    }

    override func tableView(tableView: UITableView,
                            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let recipientCellID = "RecipientCell"
        let subjectTableViewCellID = "SubjectTableViewCell"
        let messageBodyCellID = "MessageBodyCell"
        let contactTableViewCellID = "ContactTableViewCell"

        if model.tableMode == UIModel.Mode.Normal {
            // Normal mode
            if indexPath.row < subjectRowNumber {
                // Recipient cell
                let cell = tableView.dequeueReusableCellWithIdentifier(
                    recipientCellID, forIndexPath: indexPath) as! RecipientCell
                cell.recipientType = RecipientType.fromRawValue(indexPath.row + 1)
                cell.recipientTextField.delegate = self
                cell.recipientTextField.addTarget(
                    self, action: #selector(self.recipientTextHasChanged),
                    forControlEvents: .EditingChanged)

                if cell.recipientType == .To &&
                    recipientCellsByTextField[cell.recipientTextField] == nil {
                    // First time the cell got created, give it focus
                    cell.recipientTextField.becomeFirstResponder()
                }

                // Cache the cell for later use
                recipientCellsByTextField[cell.recipientTextField] = cell
                recipientCells[indexPath.row] = cell

                return cell
            } else if indexPath.row == subjectRowNumber {
                // subject cell
                let cell = tableView.dequeueReusableCellWithIdentifier(
                    subjectTableViewCellID, forIndexPath: indexPath) as! SubjectTableViewCell
                // Store for later access
                subjectTextField = cell.subjectTextField
                return cell
            } else { // if indexPath.row == bodyTextRowNumber
                // Body message cell
                let cell = tableView.dequeueReusableCellWithIdentifier(
                    messageBodyCellID, forIndexPath: indexPath) as! MessageBodyCell
                cell.bodyTextView.text = emptyBodyTextMessage
                cell.bodyTextView.delegate = self

                // Store the body text field for later access
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

extension ComposeViewController: UITextViewDelegate {
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

    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if textView == longBodyMessageTextView {
            if longBodyMessageTextView?.text == emptyBodyTextMessage {
                longBodyMessageTextView?.text = ""
            }
        }
        return true
    }

    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        if textView == longBodyMessageTextView {
            if longBodyMessageTextView?.text == "" || longBodyMessageTextView?.text == nil {
                longBodyMessageTextView?.text = emptyBodyTextMessage
            }
        }
        return true
    }
}

// MARK: -- UITextFieldDelegate (for any recipient text field)

extension ComposeViewController: UITextFieldDelegate {
    func isFreshlyEnteredTextProbablyEmail(oldText: String, newText: String,
                                           delimiter: String) -> Bool {
        return newText != "\(delimiter) " && !oldText.matchesPattern("\(delimiter) $") &&
            newText.removeTrailingPattern(
                "\(delimiter)\\s*").isProbablyValidEmailListSeparatedBy(delimiter)
    }

    func attibutedStringFromEmailsWithColors(
        emailsAndColor: [(String, UIColor?)]) -> NSMutableAttributedString {
        let string = NSMutableAttributedString()
        let spacerString = NSAttributedString.init(string: self.delimiterWithSpace)
        for (email, color) in emailsAndColor {
            if string.length > 0 {
                string.appendAttributedString(spacerString)
            }
            let emailString: NSAttributedString?
            if let c = color {
                emailString = NSAttributedString.init(
                    string: email, attributes: [NSBackgroundColorAttributeName: c])
            } else {
                emailString = NSAttributedString.init(string: email)
            }
            if let es = emailString {
                string.appendAttributedString(es)
            }
        }
        return string
    }

    func colorReceiverTextField(textField: UITextField) {
        if let text = textField.text {
            let endsWithDelimiter = text.matchesPattern("\(recipientStringDelimiter)\\s*$")
            print("text: \(text), endsWithDelimiter: \(endsWithDelimiter)")
            if let context = appConfig?.coreDataUtil.privateContext() {
                context.performBlock() {
                    let model = Model.init(context: context)
                    let emails = text.componentsSeparatedByString(
                        self.recipientStringDelimiter).map({$0.trimmedWhiteSpace()})
                    let emailsFiltered = emails.filter() { element in
                        return element != ""
                    }
                    var emailsAndColor: [(String, UIColor?)] = []
                    for email in emailsFiltered {
                        if let contact = model.contactByEmail(email) {
                            let rating = PEPUtil.colorRatingForContact(contact)
                            let pepColor = PEPUtil.abstractPepColorFromPepColor(rating)
                            let uiColor = UIHelper.recipientTextColorFromPepColor(pepColor)
                            emailsAndColor.append((email, uiColor))
                        }
                    }
                    if emailsAndColor.count > 0 {
                        let coloredString = self.attibutedStringFromEmailsWithColors(
                            emailsAndColor)
                        if endsWithDelimiter {
                            coloredString.appendAttributedString(
                                NSAttributedString.init(string: self.delimiterWithSpace,
                                attributes: nil))
                        }
                        GCD.onMain() {
                            textField.attributedText = coloredString
                            print("coloredString: \(coloredString)")
                        }
                    }
                }
            }
        }
    }

    @objc func recipientTextHasChanged(textField: UITextField) {
        updateViewFromRecipients()
        colorReceiverTextField(textField)
    }

    func textField(textField: UITextField,
                   shouldChangeCharactersInRange range: NSRange,
                                                 replacementString string: String) -> Bool {
        if let cell = recipientCellsByTextField[textField] {
            if let text = textField.text {
                if string == " " {
                    let newText = text.stringByReplacingCharactersInRange(
                        range, withString: delimiterWithSpace)
                    if isFreshlyEnteredTextProbablyEmail(
                        text, newText: newText, delimiter: recipientStringDelimiter) {
                        textField.text = newText
                        resetTableViewToNormal()
                    }
                    return false
                }
                if string == newline {
                    if isFreshlyEnteredTextProbablyEmail(
                        text, newText: text, delimiter: recipientStringDelimiter) {
                        resetTableViewToNormal()
                    }
                    return false
                }
                let newText = text.stringByReplacingCharactersInRange(range, withString: string)
                let lastPart = newText.unfinishedRecipientPart()
                if lastPart == "" {
                    resetTableViewToNormal()

                    // For some reason, we have to do that manually.
                    // Maybe the changing of hierarchy (due to the mode change)
                    // interferes with the replacement that would happen when
                    // returning true.
                    textField.text = newText.finishedRecipientPart()
                    return false
                } else {
                    model.searchSnippet = lastPart
                    model.tableMode = .Search
                    model.contacts = []
                    model.recipientCell = cell
                    updateContacts()
                    return true
                }
            }
        }
        // If the tf is not a recipient tf, or if the text is still nil
        return true
    }
}