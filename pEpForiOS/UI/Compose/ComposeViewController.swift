//
//  ComposeViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

import MessageModel

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

class PhotoAttachment {
    static let contentType = "image/JPEG"

    let image: UIImage

    init(image: UIImage) {
        self.image = image
    }
}

open class ComposeViewController: UITableViewController, UINavigationControllerDelegate {
    struct UIModel {
        enum Mode {
            case normal
            case search
        }

        var tableMode: Mode = .normal

        var searchSnippet: String? = nil

        /**
         The search table model.
         */
        var contacts: [AddressbookContact] = []

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
        var attachments = [Attachment]()

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

    let delimiterChars: CharacterSet = CharacterSet.init(charactersIn: ":,")

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
    var messageToSend: Message?

    /**
     For determining if we give the focus to the to text field.
     */
    var firstTimeToCellWasCreated = false

    /**
     For showing sending mail activity.
     */
    lazy var activityIndicator = UIActivityIndicatorView.init(activityIndicatorStyle: .gray)

    /**
     This originally contains the send button. We need that when exchanging the send
     button for the activity indicator.
     */
    var originalRightBarButtonItem: UIBarButtonItem?

    /**
     Queue for background operations, like checking outgoing message color.
     */
    let operationQueue = OperationQueue()

    /** Pattern for removing any trailing "," and whitespace from recipients */
    let trailingPattern: String

    /** Pattern for removing the title part, like "To: " */
    let leadingPattern = "\\w*:\\s*"

    enum ComposeMode {
        /** Plain old compose */
        case normal

        /** Reply to from */
        case replyFrom

        /** Reply to all */
        case replyAll

        /** Forward */
        case forward

        /** Composing a previously drafted email */
        case composeDraft
    }

    /**
     Choose whether this should be a simple compose, or reply, forward etc.
     */
    var composeMode: ComposeMode = .normal

    /**
     For certain values of `composeMode`, there will be an email to act on
     (like reply, forward, compose draft). This is it.
     */
    var originalMessage: Message?

    /**
     The original text attributes from a recipient cell text.
     */
    var recipientTextAttributes: [String : AnyObject]?

    required public init?(coder aDecoder: NSCoder) {
        delimiterWithSpace = "\(recipientStringDelimiter) "
         trailingPattern = "\(recipientStringDelimiter)\\s*"
        super.init(coder: aDecoder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(tableView)
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let forwardedMessage = forwardedMessage() {
            // If we forward a message, add its contents as data
            let op = MessageToAttachmentOperation.init(message: forwardedMessage)
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

        overrideBackButton()
        updateViewFromRecipients()
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == unwindToEmailListSaveDraftSegue {
            guard let vc = segue.destination as? EmailListViewController else {
                return
            }
            vc.draftMessageToStore = messageForSending()
        } else if segue.identifier == unwindToEmailListSegue {
        }
    }

    func overrideBackButton() {
        let barButton = UIBarButtonItem.init(
            title: NSLocalizedString("Cancel", comment: "Abort the message composition"),
            style: .plain, target: self, action: #selector(handleSaveDraftQuery))
        navigationItem.leftBarButtonItem = barButton
    }

    func handleSaveDraftQuery() {
        if model.isDirty {
            let alert = UIAlertController.init(
                title: nil, message: nil, preferredStyle: .actionSheet)

            let actionDelete = UIAlertAction.init(
                title: NSLocalizedString(
                    "Delete Draft", comment: "Cancel message composition without save"),
                style: .destructive, handler: { alert in
                    self.performSegue(withIdentifier: self.unwindToEmailListSegue,
                        sender: nil)
            })
            alert.addAction(actionDelete)

            let actionSave = UIAlertAction.init(
                title: NSLocalizedString(
                    "Save Draft", comment: "Save draft message"),
                style: .default, handler: { alert in
                    self.performSegue(withIdentifier: self.unwindToEmailListSaveDraftSegue,
                        sender: nil)
            })
            alert.addAction(actionSave)

            let actionCancel = UIAlertAction.init(
                title: NSLocalizedString(
                    "Cancel", comment: "Abort the abort of message composition :)"),
                style: .cancel, handler: nil)
            alert.addAction(actionCancel)

            present(alert, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: self.unwindToEmailListSegue, sender: nil)
        }
    }

    func updateContacts() {
        if let snippet = model.searchSnippet {
            if let privateMOC = appConfig?.coreDataUtil.privateContext() {
                privateMOC.perform() {
                    let modelBackground = CdModel.init(context: privateMOC)
                    let contacts = modelBackground.contactsBySnippet(snippet).map() {
                        AddressbookContact.init(contact: $0)
                    }
                    GCD.onMain() {
                        self.model.contacts.removeAll()

                        // At the moment, append(contentsOf:) does not work
                        for c in contacts {
                            self.model.contacts.append(c)
                        }

                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    func resetTableViewToNormal() {
        model.searchSnippet = ""
        model.tableMode = .normal
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
            if let text = tf?.text {
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
        sendButton.isEnabled = !allEmpty && allCorrect
        if !sendButton.isEnabled {
            setPrivacyColor(PEP_color_no_color, toSendButton: sendButton)
        }
        return sendButton.isEnabled
    }

    func setPrivacyColor(_ color: PEP_color, toSendButton: UIBarButtonItem) {
        var image: UIImage?
        if let uiColor = UIHelper.sendButtonBackgroundColorFromPepColor(color) {
            image = UIHelper.imageFromColor(uiColor)
        }
        toSendButton.setBackgroundImage(image, for: UIControlState(),
                                        barMetrics: UIBarMetrics.default)
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
                if !op.isCancelled {
                    if let pepColor = op.pepColorRating {
                        let color = PEPUtil.pEpColorFromRating(pepColor)
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
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if originalRightBarButtonItem == nil {
                // save the origignal
                originalRightBarButtonItem = navigationItem.rightBarButtonItem
            }
            activityIndicator.startAnimating()
            let barButtonWithActivity = UIBarButtonItem.init(customView: activityIndicator)
            navigationItem.rightBarButtonItem = barButtonWithActivity
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            // restore the original
            navigationItem.rightBarButtonItem = originalRightBarButtonItem
            activityIndicator.stopAnimating()
        }
    }

    /**
     Updates the given message with data from the view.
     */
    func populate(message: Message, account: Account,
                  model: ICdModel) {
        // reset
        message.to = []
        message.cc = []
        message.bcc = []

        message.shortMessage = nil
        message.longMessage = nil
        message.longMessageFormatted = nil

        message.references = []

        // from
        message.from = account.user

        // recipients
        for (_, cell) in recipientCells {
            let tf = cell.recipientTextView
            if var text = tf?.text {
                text = text.removeLeadingPattern(leadingPattern)
                if !text.isOnlyWhiteSpace() {
                    let mailStrings1 = text.components(separatedBy: recipientStringDelimiter).map() {
                        $0.trimmedWhiteSpace()
                    }
                    let mailStrings2 = mailStrings1.filter() {
                        !$0.isOnlyWhiteSpace()
                    }
                    let contacts: [Identity] = mailStrings2.map() {
                        return Identity.create(address: $0)
                    }
                    if contacts.count > 0, let rt = cell.recipientType {
                        switch rt {
                        case .to:
                            message.to = contacts
                        case .cc:
                            message.cc = contacts
                        case .bcc:
                            message.bcc = contacts
                        }
                    }
                }
            }
        }

        if let subjectText = subjectTextField?.text {
            message.shortMessage = subjectText
        }

        if let bodyText = longBodyMessageTextView?.text {
            message.longMessage = bodyText
        }
    }

    /**
     Updates the given message with data from the original message,
     if it exists (e.g., reply)
     */
    func populateWithReplyData(message: Message) {
        guard let om = replyFromMessage() else {
            return
        }
        setupMessageReferences(parent: om, message: message)
    }

    /**
     Sets up the references between a parent message (i.e., a message replied to),
     and a child message (i.e., the message containing the reply).
     See https://cr.yp.to/immhf/thread.html for general strategy.
     */
    func setupMessageReferences(parent: Message, message: Message) {
        // Inherit all references from the parent
        message.references = parent.references

        // Add the parent to the references
        message.references.append(parent.messageID)
    }

    /**
     Updates the given message with data from the forwarded message,
     if it exists.
     - Note: The forwarded mail attachment was already added to the model,
     it will be handled by the general attachment handling in another function.
     */
    func populateWithForwardedData(message: Message) {
        guard let _ = forwardedMessage() else {
            return
        }

        guard let _ = appConfig?.model else {
            Log.warnComponent(comp, "Can't do anything without model")
            return
        }
    }

    func populate(message: Message, withAttachmentsFromTextView theTextView: UITextView?) {
        guard let textView = theTextView else {
            Log.warnComponent(comp, "Trying to get attachments, but no text view")
            return
        }
        let text = textView.attributedText
        text?.enumerateAttribute(
        NSAttachmentAttributeName, in: (text?.wholeRange())!, options: []) {
            value, range, stop in
            guard let _ = value as? NSTextAttachment else {
                return
            }
        }
    }

    func messageForSending() -> Message? {
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
            messageToSend = Message.create(uuid: "")
            // TODO: IOS-222: Take account into consideration
        }

        guard let msg = messageToSend else {
            Log.warnComponent(comp, "Really need a non-nil messageToSend")
            return nil
        }

        populate(message: msg, account: account, model: appC.model)
        populateWithReplyData(message: msg)
        populateWithForwardedData(message: msg)
        populate(message: msg, withAttachmentsFromTextView: longBodyMessageTextView)

        return msg
    }

    // MARK: -- Actions

    @IBAction func sendButtonTapped(_ sender: UIBarButtonItem) {
        model.networkActivity = true
        updateNetworkActivity()

        guard let appC = appConfig else {
            Log.warnComponent(comp, "Really need a non-nil appConfig for sending mail")
            return
        }
        guard let _ = appC.currentAccount else {
            Log.warnComponent(comp, "Really need a non-nil currentAccount for sending mail")
            return
        }
        guard let _ = messageForSending() else {
            return
        }

        // TODO: IOS 222: Store message so that it will be sent
    }

    @IBAction func attachedField(_ sender: AnyObject) {
        let attachedAlertView = UIAlertController()
        attachedAlertView.title = NSLocalizedString("AttachedFiles",
                          comment: "Title for attached files alert view")
        attachedAlertView.message = NSLocalizedString("Choose one option",
        comment: "Message for attached alert view")

        let photosAction = UIAlertAction(title: NSLocalizedString(
            "Photos / Videos",
            comment: "Title for photos/videos action in attached files alert view"),
            style: UIAlertActionStyle.default) {
            UIAlertAction in
                let possibleAttachedImages = UIImagePickerController.init()
                possibleAttachedImages.modalPresentationStyle = UIModalPresentationStyle.currentContext
                possibleAttachedImages.delegate = self
                possibleAttachedImages.allowsEditing = false
                possibleAttachedImages.sourceType = .photoLibrary
                if let mediaTypes = UIImagePickerController.availableMediaTypes(
                    for: .photoLibrary) {
                    possibleAttachedImages.mediaTypes = mediaTypes
                } else {
                    possibleAttachedImages.mediaTypes = [kUTTypeImage as String,
                                                         kUTTypeMovie as String]
                }
                self.present(possibleAttachedImages, animated: true, completion: nil)
            }
        attachedAlertView.addAction(photosAction)

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel",
                comment: "Cancel button text for email actions menu (reply, forward etc.)"),
            style: .cancel) { (action) in }

        attachedAlertView.addAction(cancelAction)

         present(attachedAlertView, animated: true, completion: nil)
    }

    // MARK: -- UITableViewDelegate

    override open func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        if model.tableMode == UIModel.Mode.search {
            if let cell = model.recipientCell {
                return cell.bounds.height
            }
        }
        return 0
    }

    override open func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        if model.tableMode == UIModel.Mode.search && section == 0 {
            // We are reusing an ordinary cell as a header, this might lead to:
            // "no index path for table cell being reused".
            // Can probably ignored.
            return model.recipientCell
        }
        return nil
    }

    override open func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView,
                   forSection section: Int) {
        if model.tableMode == UIModel.Mode.search && section == 0 {
            model.recipientCell?.recipientTextView.becomeFirstResponder()
        }
    }

    override open func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        if model.tableMode == UIModel.Mode.search {
            if let cell = model.recipientCell {
                let c = model.contacts[(indexPath as NSIndexPath).row]
                if let r = ComposeViewHelper.currentRecipientRangeFromText(
                    cell.recipientTextView.text as NSString,
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

    override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        if model.tableMode == UIModel.Mode.normal {
            if let cell = model.recipientCell {
                cell.recipientTextView.becomeFirstResponder()
            }
            if (indexPath as NSIndexPath).row == bodyTextRowNumber {
                cell.separatorInset = UIEdgeInsets.init(top: 0,left: cell.bounds.size.width/2,
                                                        bottom: 0,right: cell.bounds.size.width/2)

            }
        }
    }

    // MARK: -- UITableViewDataSource

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if model.tableMode == UIModel.Mode.normal {
            return bodyTextRowNumber + 1
        } else {
            return model.contacts.count
        }
    }

    /**
     - Returns: The original message to be replied on, if it's a reply.
     */
    func replyFromMessage() -> Message? {
        if composeMode == .replyFrom {
            if let om = originalMessage {
                return om
            }
        }
        return nil
    }

    /**
     - Returns: The message that has to be forwarded.
     */
    func forwardedMessage() -> Message? {
        if composeMode == .forward {
            if let om = originalMessage {
                return om
            }
        }
        return nil
    }

    /**
     - Returns: The draft message that should be used as a base for the compose.
     */
    func composeFromDraftMessage() -> Message? {
        if composeMode == .composeDraft {
            if let om = originalMessage {
                return om
            }
        }
        return nil
    }

    override open func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let recipientCellID = "RecipientCell"
        let subjectTableViewCellID = "SubjectTableViewCell"
        let messageBodyCellID = "MessageBodyCell"
        let contactTableViewCellID = "ContactTableViewCell"

        if model.tableMode == UIModel.Mode.normal {
            // Normal mode
            if (indexPath as NSIndexPath).row < subjectRowNumber {
                // Recipient cell
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: recipientCellID, for: indexPath) as! RecipientCell

                if cell.recipientType == nil {
                    cell.recipientType = RecipientType.fromRawValue((indexPath as NSIndexPath).row + 1)
                    cell.recipientTextView.delegate = self

                    // Cache the cell for later use
                    recipientCellsByTextView[cell.recipientTextView] = cell
                    recipientCells[(indexPath as NSIndexPath).row] = cell

                    cell.recipientTextView.font = UIFont.preferredFont(
                        forTextStyle: UIFontTextStyle.body)

                    var changedRecipients = false

                    // Handle message compose for all recipient fields
                    if let composeMessage = composeFromDraftMessage() {
                        let contacts = ComposeViewHelper.contactsForRecipientType(
                            cell.recipientType, fromMessage: composeMessage)
                        if contacts.count > 0 {
                            changedRecipients = true
                        }
                        ComposeViewHelper.transfer(
                            identities: contacts, toTextField: cell.recipientTextView,
                            titleText: cell.titleText)
                    }

                    // Handle reply to for .To
                    if cell.recipientType == .to {
                        if let om = replyFromMessage() {
                            if let from = om.from {
                                ComposeViewHelper.transfer(
                                    identities: [from], toTextField: cell.recipientTextView,
                                    titleText: cell.titleText)
                                changedRecipients = true
                            }
                        } else {
                            // First time the cell got created, give it focus
                            cell.recipientTextView.becomeFirstResponder()
                        }
                    }

                    if recipientTextAttributes == nil {
                        var attributeRange: NSRange = NSMakeRange(0, 1)
                        recipientTextAttributes =
                            cell.recipientTextView.attributedText.attributes(
                                at: 0, longestEffectiveRange: &attributeRange,
                                in: NSRange.init(location: 0, length: 1)) as [String : AnyObject]?
                    }

                    if changedRecipients {
                        updateViewFromRecipients()
                        colorRecipients(cell.recipientTextView)
                    }
                }

                return cell
            } else if (indexPath as NSIndexPath).row == subjectRowNumber {
                // subject cell
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: subjectTableViewCellID, for: indexPath) as! SubjectTableViewCell
                // Store for later access
                subjectTextField = cell.subjectTextField

                cell.subjectTextField.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)

                cell.subjectTextField.delegate = self

                if let m = replyFromMessage() {
                    subjectTextField?.text = ReplyUtil.replySubjectForMail(m)
                }

                if let m = composeFromDraftMessage() {
                    subjectTextField?.text = m.shortMessage
                }

                return cell
            } else { // if indexPath.row == bodyTextRowNumber
                // Body message cell
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: messageBodyCellID, for: indexPath) as! MessageBodyCell
                cell.bodyTextView.delegate = self

                // Store the body text field for later access
                longBodyMessageTextView = cell.bodyTextView

                cell.bodyTextView.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)

                let replyAll = composeMode == .replyAll
                if let om = replyFromMessage() {
                    let text = ReplyUtil.quotedMailTextForMail(om, replyAll: replyAll)
                    cell.bodyTextView.text = text
                    cell.bodyTextView.selectedRange = NSRange.init(location: 0, length: 0)
                } else {
                    cell.bodyTextView.text = "\n\n\(ReplyUtil.footer())"
                    cell.bodyTextView.selectedRange = NSRange.init(location: 0, length: 0)
                }

                if let om = composeFromDraftMessage() {
                    cell.bodyTextView.text = om.longMessage
                }

                // Give it the focus, if it's not a reply. For non-replies, the to text
                // field will get the focus.
                if composeMode == .replyFrom || composeMode == .replyAll {
                    cell.bodyTextView.becomeFirstResponder()
                }

                return cell
            }
        } else {
            // Search mode
            let contactIndex = (indexPath as NSIndexPath).row
            let contact = model.contacts[contactIndex]
            let cell = tableView.dequeueReusableCell(
                withIdentifier: contactTableViewCellID, for: indexPath) as! ContactTableViewCell
            cell.contact = contact
            return cell
        }
    }

    // MARK: -- Handling recipient text input

    /**
     Gives contacts in the given text view the pEp color rating.
     */
    func colorRecipients(_ textView: UITextView) {
        let parts = textView.text.components(separatedBy: delimiterChars)
        if parts.count == 0 {
            return
        }
        guard let ap = appConfig else {
            return
        }
        guard let origAttributes = recipientTextAttributes else {
            return
        }

        let model = CdModel.init(context: ap.coreDataUtil.privateContext())

        model.context.perform() {
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
                    recipientText.append(attributed)
                    recipientText.append(NSAttributedString.init(string: ": ",
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
                    recipientText.append(attributed)
                    recipientText.append(NSAttributedString.init(
                        string: self.delimiterWithSpace,
                        attributes: origAttributes))
                }
            }
            GCD.onMain() {
                textView.attributedText = recipientText
            }
        }
    }

    func updateSearch(_ textView: UITextView) {
        if let searchSnippet = ComposeViewHelper.extractRecipientFromText(
            textView.text as NSString, aroundCaretPosition: textView.selectedRange.location) {
            model.searchSnippet = searchSnippet
            model.tableMode  = .search
            model.recipientCell = recipientCellsByTextView[textView]
            updateContacts()
        }
    }

    // MARK: -- Util

    /**
     This has to be called whenever the body text changes, so the table view resizes that cell.
     */
    func resizeTableView() {
        let currentOffset = tableView.contentOffset
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
        tableView.setContentOffset(currentOffset, animated: false)
    }
}

// MARK: -- UIImagePickerControllerDelegate

extension ComposeViewController: UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo
        info: [String : Any]) {
        guard let attachedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }

        let photoAttachment = PhotoAttachment.init(image: attachedImage)

        insert(imageAttachment: photoAttachment)

        dismiss(animated: true, completion: nil)
    }

    func insert(imageAttachment: PhotoAttachment) {
        guard let textView = longBodyMessageTextView else {
            return
        }

        let textAttachment = NSTextAttachment()
        textAttachment.image = imageAttachment.image
        let imageString = NSAttributedString(attachment:textAttachment)

        textAttachment.bounds = obtainContainerToMaintainRatio(
            textView.bounds.width, rectangle: imageAttachment.image.size)

        let selectedRange = textView.selectedRange
        let attrText = NSMutableAttributedString.init(attributedString: textView.attributedText)
        attrText.replaceCharacters(in: selectedRange, with: imageString)
        textView.attributedText = attrText

        resizeTableView()
    }
}

// MARK: -- UITextViewDelegate

extension ComposeViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        if textView == longBodyMessageTextView {
            resizeTableView()
        } else if let _ = recipientCellsByTextView[textView] {
            updateSearch(textView)
        }
        model.isDirty = true
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
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

// MARK: -- UITextFieldDelegate

extension ComposeViewController: UITextFieldDelegate {
    public func textField(
        _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
        replacementString string: String) -> Bool {
        model.isDirty = true
        return true
    }
}
