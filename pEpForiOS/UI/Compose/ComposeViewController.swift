//
//  ComposeViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData
//import NSEvent

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

        /**
         Set to `true` as soon as the user has changed the body text, or added a recipient.
         Used for determining whether a draft should be stored.
         */
        var isDirty = false
    }

    var model: UIModel = UIModel.init()

    let comp = "ComposeViewController"

    /**
     Segue name back to email list when email was sent successfully.
     */
    let unwindToEmailListMailSentSegue = "unwindToEmailListMailSentSegue"

    /**
     Segue name back to email list when a draft mail should be stored.
     */
    let unwindToEmailListSaveDraftSegue = "unwindToEmailListSaveDraftSegue"

    /**
     Segue name back to email list, doing nothing else.
     */
    let unwindToEmailListSegue = "unwindToEmailListSegue"

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
    @IBOutlet weak var attachedButton: UIButton!

    /**
     The row number of the cell containing the subject of the message for the user to write.
     */
    let subjectRowNumber = 3

    /**
     The row number of the cell containing the body of the message.
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
                            // TODO: Update attachment display!
                        }
                    }
                }
                operationQueue.addOperation(op)
            }
        }

        overrideBackButton()
        updateViewFromRecipients()
    }

    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == unwindToEmailListSaveDraftSegue {
            guard let vc = segue.destinationViewController as? EmailListViewController else {
                return
            }
            vc.draftMessageToStore = messageForSending()
        } else if segue.identifier == unwindToEmailListSegue {
        }
    }

    func overrideBackButton() {
        let barButton = UIBarButtonItem.init(
            title: NSLocalizedString("Cancel", comment: "Abort the message composition"),
            style: .Plain, target: self, action: #selector(handleSaveDraftQuery))
        navigationItem.leftBarButtonItem = barButton
    }

    func handleSaveDraftQuery() {
        if model.isDirty {
            let alert = UIAlertController.init(
                title: nil, message: nil, preferredStyle: .ActionSheet)

            let actionDelete = UIAlertAction.init(
                title: NSLocalizedString(
                    "Delete Draft", comment: "Cancel message composition without save"),
                style: .Destructive, handler: { alert in
                    self.performSegueWithIdentifier(self.unwindToEmailListSegue,
                        sender: nil)
            })
            alert.addAction(actionDelete)

            let actionSave = UIAlertAction.init(
                title: NSLocalizedString(
                    "Save Draft", comment: "Save draft message"),
                style: .Default, handler: { alert in
                    self.performSegueWithIdentifier(self.unwindToEmailListSaveDraftSegue,
                        sender: nil)
            })
            alert.addAction(actionSave)

            let actionCancel = UIAlertAction.init(
                title: NSLocalizedString(
                    "Cancel", comment: "Abort the abort of message composition :)"),
                style: .Cancel, handler: nil)
            alert.addAction(actionCancel)

            presentViewController(alert, animated: true, completion: nil)
        } else {
            self.performSegueWithIdentifier(self.unwindToEmailListSegue, sender: nil)
        }
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
        toSendButton.setBackgroundImage(image, forState: .Normal,
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
            op.pepMail = ComposeViewHelper.pepMailFromViewForCheckingRating(self)
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

    func messageForSending() -> IMessage? {
        guard let appC = appConfig else {
            Log.warnComponent(
                comp, "Really need a non-nil appConfig for creating send message")
            return nil
        }
        guard let account = appC.currentAccount else {
            Log.warnComponent(comp, "Really need a non-nil currentAccount")
            return nil
        }

        if messageToSend == nil {
            messageToSend = appC.model.insertNewMessageForSendingFromAccountEmail(
                account.email)
        }

        guard let msg = messageToSend else {
            Log.warnComponent(comp, "Really need a non-nil messageToSend")
            return nil
        }

        populateMessageWithViewData(msg, account: account, model: appC.model)
        populateMessageWithReplyData(msg)
        populateMessageWithForwardedData(msg)

        return msg
    }

    // MARK: -- Actions

    @IBAction func sendButtonTapped(sender: UIBarButtonItem) {
        model.networkActivity = true
        updateNetworkActivity()

        guard let appC = appConfig else {
            Log.warnComponent(comp, "Really need a non-nil appConfig for sending mail")
            return
        }
        guard let account = appC.currentAccount else {
            Log.warnComponent(comp, "Really need a non-nil currentAccount for sending mail")
            return
        }
        guard let msg = messageForSending() else {
            return
        }

        appC.grandOperator.sendMail(
            msg, account: account as! Account, completionBlock: { error in
                Log.errorComponent(self.comp, error: error)
                GCD.onMain() {
                    self.model.networkActivity = false
                    self.updateNetworkActivity()

                    UIHelper.displayError(
                        error, controller: self,
                        title: NSLocalizedString("Error sending message",
                            comment: "Title for the 'Error sending mail' dialog"))
                    if error == nil {
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
                if let r = ComposeViewHelper.currentRecipientRangeFromText(
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

    /**
     - Returns: The draft message that should be used as a base for the compose.
     */
    func composeFromDraftMessage() -> IMessage? {
        if composeMode == .ComposeDraft {
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

                    cell.recipientTextView.font = UIFont.preferredFontForTextStyle(
                        UIFontTextStyleBody)

                    if cell.recipientType == .To {
                        if let om = replyFromMessage() {
                            if let from = om.from {
                                ComposeViewHelper.transferContacts(
                                    [from], toTextField: cell.recipientTextView,
                                    titleText: cell.titleText)
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

                cell.subjectTextField.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

                cell.subjectTextField.delegate = self

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

                cell.bodyTextView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

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

                if !model.attachments.isEmpty {
                    for attachment in model.attachments {
                        guard let image = attachment.image else {
                            continue
                        }
                        let textAttachment = NSTextAttachment()
                        textAttachment.image = image
                        let imageString = NSAttributedString(attachment:textAttachment)
                        cell.bodyTextView.attributedText = imageString
                        textAttachment.bounds = obtainContainerToMaintainRatio(
                            cell.bodyTextView.bounds.width,
                            rectangle: image.size)
                        let range = cell.bodyTextView.selectedTextRange
                        //let range = range?.end

                        //print(range)
                    }
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
        if let searchSnippet = ComposeViewHelper.extractRecipientFromText(
            textView.text, aroundCaretPosition: textView.selectedRange.location) {
            model.searchSnippet = searchSnippet
            model.tableMode  = .Search
            model.recipientCell = recipientCellsByTextView[textView]
            updateContacts()
        }
    }

    public func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo
                            info: [String : AnyObject]) {
        guard let attachedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        let simpleAttachmentImage = SimpleAttachment.init(filename: nil,
                                                          contentType: "image/JPEG",
                                                          data: nil,
                                                          image: attachedImage)
        model.attachments.append(simpleAttachmentImage)
        let indexPath = NSIndexPath(forRow: bodyTextRowNumber, inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Top)

        dismissViewControllerAnimated(true, completion: nil)
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
        model.isDirty = true
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

                // Email was modified.
                // Set this here because in this case textViewDidChange won't catch it.
                model.isDirty = true

                return false
            }
            updateViewFromRecipients()
        }
        // setting the model to dirty will be handled by textViewDidChange
        return true
    }
}

extension ComposeViewController: UITextFieldDelegate {
    public func textField(
        textField: UITextField, shouldChangeCharactersInRange range: NSRange,
        replacementString string: String) -> Bool {
        model.isDirty = true
        return true
    }
}