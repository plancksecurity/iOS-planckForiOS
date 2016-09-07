//
//  ComposeViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class ComposeViewController: UITableViewController, UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate {
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

        /**
         If there are attachments, they should be stored here, and displayed in the view.
         */
        var attachments = [SimpleAttachment]()
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

    let delimiterChars: NSCharacterSet = NSCharacterSet.init(charactersInString: ":,")

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
    var recipientCellsByTextView = [UITextView: RecipientCell]()

    /**
     The recipient cells, mapped by their index row.
     */
    var recipientCells = [Int: RecipientCell]()

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

    /**
     Queue for background operations, like checking outgoing message color.
     */
    let operationQueue = NSOperationQueue()

    /** Pattern for removing any trailing "," and whitespace from recipients */
    let trailingPattern: String

    /** Pattern for removing the title part, like "To: " */
    let leadingPattern = "\\w*:\\s*"

    enum ComposeMode {
        /** Plain old compose */
        case Normal

        /** Reply to from */
        case ReplyFrom

        /** Reply to all */
        case ReplyAll

        /** Forward */
        case Forward
    }

    /**
     Choose whether this should be a simple compose, or reply, forward etc.
     */
    var composeMode: ComposeMode = .Normal

    /**
     For certain values of `composeMode`, there will be an email to act on
     (like reply, forward). This is it.
     */
    var originalMessage: IMessage?

    /**
     The original text attributes from a recipient cell text.
     */
    var recipientTextAttributes: [String : AnyObject]?

    required public init?(coder aDecoder: NSCoder) {
        delimiterWithSpace = "\(recipientStringDelimiter) "
         trailingPattern = "\(recipientStringDelimiter)\\s*"
        super.init(coder: aDecoder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(tableView)
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let forwardedMessage = forwardedMessage() {
            // If we forward a message, add its contents as data
            if let ac = appConfig {
                let op = MessageToAttachmentOperation.init(
                    message: forwardedMessage, coreDataUtil: ac.coreDataUtil)
                op.completionBlock = {
                    GCD.onMain() {
                        if let attch = op.attachment {
                            self.model.attachments.append(attch)
                            // TODO: Update display!
                        }
                    }
                }
                operationQueue.addOperation(op)
            }
        }

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
            let tf = cell.recipientTextView
            if let text = tf.text {
                let trailingRemoved = text.removeTrailingPattern(trailingPattern)
                let leadingRemoved = trailingRemoved.removeLeadingPattern(leadingPattern)
                if !leadingRemoved.isOnlyWhiteSpace() {
                    allEmpty = false
                    if !leadingRemoved.isProbablyValidEmailListSeparatedBy(
                        recipientStringDelimiter) {
                        allCorrect = false
                    }
                }
            }
        }
        sendButton.enabled = !allEmpty && allCorrect
        if !sendButton.enabled {
            setPrivacyColor(PEP_color_no_color, toSendButton: sendButton)
        }
        return sendButton.enabled
    }

    func setPrivacyColor(color: PEP_color, toSendButton: UIBarButtonItem) {
        var image: UIImage?
        if let uiColor = UIHelper.sendButtonBackgroundColorFromPepColor(color) {
            image = UIHelper.imageFromColor(uiColor)
        }
        self.sendButton.setBackgroundImage(image, forState: .Normal,
                                           barMetrics: UIBarMetrics.Default)
    }

    /**
     Whenever one of the recipients field changes, call this to validate them,
     update colors, etc.
     */
    func updateViewFromRecipients() {
        // Checking mail color only makes sense if you can actually send that mail,
        // hence the if.
        if updateSendButtonFromView() {
            if operationQueue.operationCount > 0 {
                // We have an existing ops, let's cancel them and don't do anything else
                operationQueue.cancelAllOperations()
                Log.warnComponent(comp, "Won't check outgoing color, already one in operation")
                return
            }
            let op = OutgoingMessageColorOperation()
            op.pepMail = pepMailFromViewForCheckingRating()
            op.completionBlock = {
                if !op.cancelled {
                    if let pepColor = op.pepColorRating {
                        let color = PEPUtil.colorFromPepRating(pepColor)
                        GCD.onMain() {
                            self.setPrivacyColor(color, toSendButton: self.sendButton)
                        }
                    } else {
                        Log.warnComponent(self.comp, "Could not get outgoing message color")
                    }
                }
            }
            operationQueue.addOperation(op)
        }
    }

    /**
     If there is network activity, show it.
     */
    func updateNetworkActivity() {
        if model.networkActivity {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            if originalRightBarButtonItem == nil {
                // save the origignal
                originalRightBarButtonItem = navigationItem.rightBarButtonItem
            }
            activityIndicator.startAnimating()
            let barButtonWithActivity = UIBarButtonItem.init(customView: activityIndicator)
            navigationItem.rightBarButtonItem = barButtonWithActivity
        } else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            // restore the original
            navigationItem.rightBarButtonItem = originalRightBarButtonItem
            activityIndicator.stopAnimating()
        }
    }

    /**
     Builds a pEp mail dictionary from all the related views. This is just a quick
     method for checking the pEp color rating, it's not exhaustive!
     */
    func pepMailFromViewForCheckingRating() -> PEPMail? {
        var message = PEPMail()
        for (_, cell) in recipientCells {
            let tf = cell.recipientTextView
            if let text = tf.text {
                let mailStrings0 = text.removeLeadingPattern(leadingPattern)
                if !mailStrings0.isOnlyWhiteSpace() {
                    let mailStrings1 = mailStrings0.componentsSeparatedByString(
                        recipientStringDelimiter).map() {
                            $0.trimmedWhiteSpace()
                    }

                    let mailStrings2 = mailStrings1.filter() {
                        !$0.isOnlyWhiteSpace()
                    }
                    let model = appConfig?.model
                    let contacts: [PEPContact] = mailStrings2.map() {
                        if let c = model?.contactByEmail($0) {
                            return PEPUtil.pepContact(c)
                        }
                        return PEPUtil.pepContactFromEmail($0, name: $0.namePartOfEmail())
                    }
                    if contacts.count > 0 {
                        if let rt = cell.recipientType {
                            var pepKey: String? = nil
                            switch rt {
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
        }

        guard let account = appConfig?.currentAccount else {
            Log.warnComponent(comp, "Need valid account for determining pEp rating")
            return nil
        }
        message[kPepFrom] = PEPUtil.pepContactFromEmail(
            account.email, name: account.nameOfTheUser)

        if let subjectText = subjectTextField?.text {
            message[kPepShortMessage] = subjectText
        }
        if let bodyText = longBodyMessageTextView?.text {
            message[kPepLongMessage] = bodyText
        }
        message[kPepOutgoing] = true
        return message
    }

    /**
     Updates the given message with data from the view.
     */
    func populateMessageWithViewData(message: IMessage, account: IAccount,
                                     model: IModel) {
        // reset
        message.to = []
        message.cc = []
        message.bcc = []

        message.subject = nil
        message.longMessage = nil
        message.longMessageFormatted = nil

        message.references = []

        // from
        message.from = model.insertOrUpdateContactEmail(account.email, name: account.nameOfTheUser)
            as? Contact

        // recipients
        for (_, cell) in recipientCells {
            let tf = cell.recipientTextView
            if var text = tf.text {
                text = text.removeLeadingPattern(leadingPattern)
                if !text.isOnlyWhiteSpace() {
                    let mailStrings1 = text.componentsSeparatedByString(recipientStringDelimiter).map() {
                        $0.trimmedWhiteSpace()
                    }
                    let mailStrings2 = mailStrings1.filter() {
                        !$0.isOnlyWhiteSpace()
                    }
                    let contacts: [IContact] = mailStrings2.map() {
                        let c = model.insertOrUpdateContactEmail($0, name: nil)
                        return c
                    }
                    if contacts.count > 0 {
                        if let rt = cell.recipientType {
                            let set = NSOrderedSet.init(array: contacts.map() {$0 as AnyObject})
                            switch rt {
                            case .To:
                                message.to = set
                            case .CC:
                                message.cc = set
                            case .BCC:
                                message.bcc = set
                            }
                        }
                    }
                }
            }
        }

        if let subjectText = subjectTextField?.text {
            message.subject = subjectText
        }

        if let bodyText = longBodyMessageTextView?.text {
            message.longMessage = bodyText
        }
    }

    /**
     Updates the given message with data from the original message,
     if it exists (e.g., reply)
     */
    func populateMessageWithReplyData(message: IMessage) {
        guard let om = replyFromMessage() else {
            return
        }

        guard let model = appConfig?.model else {
            Log.warnComponent(comp, "Can't do anything without model")
            return
        }

        setupMessageReferences(om, message: message, model: model)
    }

    /**
     Sets up the references between a parent message (i.e., a message replied to),
     and a child message (i.e., the message containing the reply).
     See https://cr.yp.to/immhf/thread.html for general strategy.
     */
    func setupMessageReferences(parent: IMessage, message: IMessage, model: IModel) {
        // Inherit all references from the parent
        message.references = parent.references

        // Add the parent to the references
        if let references = message.references.mutableCopy() as? NSMutableOrderedSet {
            if let omid = parent.messageID {
                let ref = model.insertOrUpdateMessageReference(omid)
                references.addObject(ref)
                message.references = references
            }
        }
    }

    /**
     Updates the given message with data from the forwarded message,
     if it exists. That means mainly the references.
     - Note: The forwarded mail attachment was already added to the model,
     it will be handled by the general attachment handling in another function.
     */
    func populateMessageWithForwardedData(message: IMessage) {
        guard let om = forwardedMessage() else {
            return
        }

        guard let model = appConfig?.model else {
            Log.warnComponent(comp, "Can't do anything without model")
            return
        }

        // TODO: Message references needed?
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

        guard let msg = messageToSend else {
            Log.warnComponent(comp, "Really need a non-nil messageToSend")
            return
        }

        populateMessageWithViewData(msg, account: account, model: appC.model)
        populateMessageWithReplyData(msg)
        populateMessageWithForwardedData(msg)

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

                        UIHelper.displayError(
                            e, controller: self,
                            title: NSLocalizedString("Error sending message",
                                comment: "Title for the 'Error sending mail' dialog"))
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

    @IBAction func attachedField(sender: AnyObject) {

        let attachedAlertView = UIAlertController()
        attachedAlertView.title = NSLocalizedString("AttachedFiles",
                          comment: "Title for attached files alert view")
        attachedAlertView.message = NSLocalizedString("Choose one option",
        comment: "Message for attached alert view")

        let videosAction = UIAlertAction(
            title: NSLocalizedString("Videos",
            comment: "Title for Video action in attached files alert view"),
            style: UIAlertActionStyle.Default) {
                UIAlertAction in
            }
        attachedAlertView.addAction(videosAction)

        let documentAction = UIAlertAction(
            title: NSLocalizedString(
                "Documents",
                comment: "Title for document action in attached files alert view"),
            style: UIAlertActionStyle.Default) {
            UIAlertAction in
        }
        attachedAlertView.addAction(documentAction)

        let photosAction = UIAlertAction(title: NSLocalizedString(
            "Photo",
            comment: "Title for photos action in attached files alert view"),
            style: UIAlertActionStyle.Default) {
            UIAlertAction in
                let possibleAttachedImages = UIImagePickerController.init()
                possibleAttachedImages.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
                possibleAttachedImages.delegate = self
                possibleAttachedImages.allowsEditing = false
                possibleAttachedImages.sourceType = .PhotoLibrary
                self.presentViewController(possibleAttachedImages, animated: true, completion: nil)
            }
        attachedAlertView.addAction(photosAction)
        presentViewController(attachedAlertView, animated: true, completion: nil)
    }

    // MARK: -- UITableViewDelegate
    override public func tableView(tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        if model.tableMode == UIModel.Mode.Search {
            if let cell = model.recipientCell {
                return cell.bounds.height
            }
        }
        return 0
    }

    override public func tableView(tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        if model.tableMode == UIModel.Mode.Search && section == 0 {
            // We are reusing an ordinary cell as a header, this might lead to:
            // "no index path for table cell being reused".
            // Can probably ignored.
            return model.recipientCell
        }
        return nil
    }

    override public func tableView(tableView: UITableView, willDisplayHeaderView view: UIView,
                   forSection section: Int) {
        if model.tableMode == UIModel.Mode.Search && section == 0 {
            model.recipientCell?.recipientTextView.becomeFirstResponder()
        }
    }

    override public func tableView(tableView: UITableView,
                            didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if model.tableMode == UIModel.Mode.Search {
            if let cell = model.recipientCell {
                let c = model.contacts[indexPath.row]
                if let r = ComposeViewController.currentRecipientRangeFromText(
                    cell.recipientTextView.text,
                    aroundCaretPosition: cell.recipientTextView.selectedRange.location) {
                    let newString = cell.recipientTextView.text.stringByReplacingCharactersInRange(
                        r, withString: " \(c.email)")
                    let replacement = "\(newString)\(delimiterWithSpace)"
                    cell.recipientTextView.text = replacement
                    colorRecipients(cell.recipientTextView)
                }
            }
            updateViewFromRecipients()
            resetTableViewToNormal()
        }
    }

    override public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
                            forRowAtIndexPath indexPath: NSIndexPath) {
        if model.tableMode == UIModel.Mode.Normal {
            if let cell = model.recipientCell {
                cell.recipientTextView.becomeFirstResponder()
            }
        }
    }

    // MARK: -- UITableViewDataSource

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if model.tableMode == UIModel.Mode.Normal {
            return bodyTextRowNumber + 1
        } else {
            return model.contacts.count
        }
    }

    /**
     - Returns: The original message to be replied on, if it's a reply.
     */
    func replyFromMessage() -> IMessage? {
        if composeMode == .ReplyFrom {
            if let om = originalMessage {
                return om
            }
        }
        return nil
    }

    /**
     - Returns: The message that has to be forwarded.
     */
    func forwardedMessage() -> IMessage? {
        if composeMode == .Forward {
            if let om = originalMessage {
                return om
            }
        }
        return nil
    }

    override public func tableView(tableView: UITableView,
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

                if cell.recipientType == nil {
                    cell.recipientType = RecipientType.fromRawValue(indexPath.row + 1)
                    cell.recipientTextView.delegate = self

                    if recipientTextAttributes == nil {
                        var attributeRange: NSRange = NSMakeRange(0, 1)
                        recipientTextAttributes =
                            cell.recipientTextView.attributedText.attributesAtIndex(
                                0, longestEffectiveRange: &attributeRange,
                                inRange: NSRange.init(location: 0, length: 1))
                    }

                    // Cache the cell for later use
                    recipientCellsByTextView[cell.recipientTextView] = cell
                    recipientCells[indexPath.row] = cell

                    if cell.recipientType == .To {
                        if let om = replyFromMessage() {
                            if let from = om.from {
                                cell.recipientTextView.text =
                                    "\(String.orEmpty(cell.titleText)) \(from.email)"
                                updateViewFromRecipients()
                                colorRecipients(cell.recipientTextView)
                            }
                        } else {
                            // First time the cell got created, give it focus
                            cell.recipientTextView.becomeFirstResponder()
                        }
                    }
                }

                return cell
            } else if indexPath.row == subjectRowNumber {
                // subject cell
                let cell = tableView.dequeueReusableCellWithIdentifier(
                    subjectTableViewCellID, forIndexPath: indexPath) as! SubjectTableViewCell
                // Store for later access
                subjectTextField = cell.subjectTextField

                if let m = replyFromMessage() {
                    subjectTextField?.text = ReplyUtil.replySubjectForMail(m)
                }

                return cell
            } else { // if indexPath.row == bodyTextRowNumber
                // Body message cell
                let cell = tableView.dequeueReusableCellWithIdentifier(
                    messageBodyCellID, forIndexPath: indexPath) as! MessageBodyCell
                cell.bodyTextView.delegate = self

                // Store the body text field for later access
                longBodyMessageTextView = cell.bodyTextView

                let replyAll = composeMode == .ReplyAll
                if let om = replyFromMessage() {
                    let text = ReplyUtil.quotedMailTextForMail(om, replyAll: replyAll)
                    cell.bodyTextView.text = text
                    cell.bodyTextView.selectedRange = NSRange.init(location: 0, length: 0)
                } else {
                    cell.bodyTextView.text = "\n\n\(ReplyUtil.footer())"
                    cell.bodyTextView.selectedRange = NSRange.init(location: 0, length: 0)
                }

                // Give it the focus, if it's not a reply. For non-replies, the to text field
                // will get the focus.
                if composeMode == .ReplyFrom || composeMode == .ReplyAll {
                    cell.bodyTextView.becomeFirstResponder()
                }

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

    // MARK: -- Handling recipient text input

    public static func currentRecipientRangeFromText(
        text: NSString, aroundCaretPosition: Int) -> NSRange? {
        let comma: UnicodeScalar = ","
        let colon: UnicodeScalar = ":"
        var start = -1
        var end = -1

        // We want the character that just was changed "under the cursor"
        let location = aroundCaretPosition - 1

        var maxIndex = text.length
        if maxIndex == 0 {
            return nil
        }

        maxIndex = maxIndex - 1

        if location > maxIndex {
            return nil
        }

        var index = location

        // Check if the user just entered a comma or colon. If yes, that's it.
        let ch = text.characterAtIndex(index)
        if UInt32(ch) == comma.value || UInt32(ch) == colon.value {
            return nil
        }

        // find beginning
        while true {
            if index < 0 {
                start = 0
                break
            }
            let ch = text.characterAtIndex(index)
            if UInt32(ch) == comma.value || UInt32(ch) == colon.value {
                start = index + 1
                break
            }
            index = index - 1
        }

        // find end
        index = location
        while true {
            if index >= maxIndex {
                end = maxIndex + 1
                break
            }
            let ch = text.characterAtIndex(index)
            if UInt32(ch) == comma.value {
                end = index
                break
            }
            index = index + 1
        }

        if end != -1 && start != -1 {
            let r = NSRange.init(location: start, length: end - start)
            if r.location >= 0 && r.location + r.length <= text.length {
                return r
            }
        }

        return nil
    }

    /**
     Tries to determine the currently edited part in a recipient text, given the
     text and the last known caret position.
     */
    public static func extractRecipientFromText(
        text: NSString, aroundCaretPosition: Int) -> String? {
        if let r = self.currentRecipientRangeFromText(
            text, aroundCaretPosition: aroundCaretPosition) {
            return text.substringWithRange(r).trimmedWhiteSpace()
        }
        return nil
    }

    /**
     Gives contacts in the given text view the pEp color rating.
     */
    func colorRecipients(textView: UITextView) {
        let parts = textView.text.componentsSeparatedByCharactersInSet(delimiterChars)
        if parts.count == 0 {
            return
        }
        guard let ap = appConfig else {
            return
        }
        guard let origAttributes = recipientTextAttributes else {
            return
        }

        let model = Model.init(context: ap.coreDataUtil.privateContext())

        model.context.performBlock() {
            let recipientText = NSMutableAttributedString.init()
            let session = PEPSession.init()
            var firstPart = true
            for p in parts {
                let thePart = p.trimmedWhiteSpace()
                if thePart.isEmpty {
                    firstPart = false
                    continue
                }
                if firstPart {
                    firstPart = false
                    let attributed = NSAttributedString.init(string: thePart,
                        attributes: origAttributes)
                    recipientText.appendAttributedString(attributed)
                    recipientText.appendAttributedString(NSAttributedString.init(string: ": ",
                        attributes: origAttributes))
                } else {
                    var attributes = origAttributes
                    if let c = model.contactByEmail(thePart) {
                        let color = PEPUtil.privacyColorForContact(c, session: session)
                        if let uiColor = UIHelper.textBackgroundUIColorFromPrivacyColor(color) {
                            attributes[NSBackgroundColorAttributeName] = uiColor
                        }
                    }
                    let attributed = NSAttributedString.init(string: thePart,
                        attributes: attributes)
                    recipientText.appendAttributedString(attributed)
                    recipientText.appendAttributedString(NSAttributedString.init(
                        string: self.delimiterWithSpace,
                        attributes: origAttributes))
                }
            }
            GCD.onMain() {
                textView.attributedText = recipientText
            }
        }
    }

    func updateSearch(textView: UITextView) {
        if let searchSnippet = ComposeViewController.extractRecipientFromText(
            textView.text, aroundCaretPosition: textView.selectedRange.location) {
            model.searchSnippet = searchSnippet
            model.tableMode  = .Search
            model.recipientCell = recipientCellsByTextView[textView]
            updateContacts()
        }
    }
}

// MARK: -- UITextViewDelegate

extension ComposeViewController: UITextViewDelegate {
    public func textViewDidChange(textView: UITextView) {
        if textView == longBodyMessageTextView {
            let currentOffset = tableView.contentOffset
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            tableView.setContentOffset(currentOffset, animated: false)
        } else if let _ = recipientCellsByTextView[textView] {
            updateSearch(textView)
        }
    }

    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange,
                  replacementText text: String) -> Bool {
        if let recipientCell = recipientCellsByTextView[textView] {
            // Disallow if check is infringing on the "readonly" part, like "To: "
            if range.location < recipientCell.minimumCaretLocation {
                updateViewFromRecipients()
                return false
            }
            if text == newline {
                resetTableViewToNormal()
                let newString = textView.text.stringByReplacingCharactersInRange(
                    range, withString: delimiterWithSpace)
                textView.text = newString
                colorRecipients(textView)
                updateViewFromRecipients()
                return false
            }
            updateViewFromRecipients()
        }
        return true
    }
}