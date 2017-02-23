//
//  ComposeViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI
import MobileCoreServices
import MessageModel

class ComposeTableViewController: UITableViewController {

    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet weak var sendButton: UIBarButtonItem!

    enum ComposeMode {
        case normal
        case replyFrom
        case replyAll
        case forward
        case draft
    }

    let contactPicker = CNContactPickerViewController()
    let imagePicker = UIImagePickerController()
    let menuController = UIMenuController.shared

    var suggestTableView: SuggestTableView!
    var tableDict: NSDictionary?
    var tableData: ComposeDataSource? = nil
    var currentCell: IndexPath!
    var allCells = MutableOrderedSet<ComposeCell>()
    var ccEnabled = false

    var appConfig: AppConfig?
    var composeMode: ComposeMode = .normal
    var messageToSend: Message?
    var originalMessage: Message?
    let operationQueue = OperationQueue()

    lazy var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    let mimeTypeController = MimeTypeUtil()

    var origin : Identity?
    var destinyTo : [Identity]?
    var destinyCc : [Identity]?
    var destinyBcc : [Identity]?

    let attachmentCounter = AttachmentCounter()
    let mimeTypeUtil = MimeTypeUtil()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        addContactSuggestTable()
        prepareFields()
        prepareColor()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setDefaultBarColors()
    }

    func prepareColor() {
        destinyTo = [Identity]()
        destinyCc = [Identity]()
        destinyBcc = [Identity]()
        if let om = originalMessage {
            if let id = om.parent?.account?.user {
                origin = id
            }
            if composeMode == .replyFrom {
                if let from = om.from {
                    destinyTo?.append(from)
                }
            }
            if composeMode == .replyAll {
                if let from = om.from {
                    destinyTo?.append(from)
                }
                let to = om.to
                for id in to {
                    if !id.isMySelf {
                        destinyTo?.append(id)
                    }
                }
                for id in om.cc {
                    destinyCc?.append(id)
                }
            }
        }
        calculateComposeColor()
    }

    // MARK: - Private Methods

    /**
     Updates the given `RecipientCell` with data from the `originalMessage`,
     if this is a suitable `ComposeMode`.
     */
    func updateInitialContent(recipientCell: RecipientCell) {
        if let fm = recipientCell.fieldModel, let om = originalMessage {
            switch fm.type {
            case .to:
                if composeMode == .replyFrom, let from = om.from {
                    recipientCell.addIdentity(from)
                }
                if composeMode == .replyAll, let from = om.from {
                    let to = om.to
                    for identity in to {
                        if !identity.isMySelf {
                            recipientCell.addIdentity(identity)
                        }
                    }
                    recipientCell.addIdentity(from)
                }
            case .cc:
                if composeMode == .replyAll {
                    for ident in om.cc {
                        recipientCell.addIdentity(ident)
                    }
                }
            case .bcc:
                //in case of Bcc we don't do anything
                break
            default:
                break
            }
        }
    }

    func updateInitialContent(messageBodyCell: MessageBodyCell) {
        if let om = originalMessage, composeMode == .replyFrom || composeMode == .replyAll {
            messageBodyCell.setInitial(
                text: ReplyUtil.quotedMessageText(message: om, replyAll: composeMode == .replyAll))
        }
        if let om = originalMessage, composeMode == .forward {
            messageBodyCell.setInitial(
                text: ReplyUtil.quotedMessageText(message: om, replyAll: composeMode == .forward))
            let mtao = MessageToAttachmentOperation(message: om)
            mtao.main()
            if let attachment = mtao.attachment {
                messageBodyCell.add(attachment)
            }
        }
    }

    func updateInitialContent(composeCell: ComposeCell) {
        if let om = originalMessage, composeMode == .replyFrom || composeMode == .replyAll {
            composeCell.setInitial(text: ReplyUtil.replySubject(message: om))
        }
        if let om = originalMessage, composeMode == .forward {
           composeCell.setInitial(text: ReplyUtil.forwardSubject(message: om))
        }
    }

    private final func prepareFields()  {
        if let path = Bundle.main.path(forResource: "ComposeData", ofType: "plist") {
            tableDict = NSDictionary(contentsOfFile: path)
        }

        if let dict = tableDict as? [String: Any] {
            tableData = ComposeDataSource(with: dict["Rows"] as! [[String: Any]])
        }
    }

    fileprivate final func openAddressBook() {
        contactPicker.delegate = self
        contactPicker.displayedPropertyKeys = [
            CNContactEmailAddressesKey, CNContactGivenNameKey, CNContactFamilyNameKey,
            CNContactMiddleNameKey, CNContactIdentifierKey]
        contactPicker.predicateForEnablingContact = NSPredicate(
            format: "emailAddresses.@count > 0")
        contactPicker.predicateForSelectionOfContact = NSPredicate(
            format: "emailAddresses.@count == 1")
        present(contactPicker, animated: true, completion: nil)
    }

    fileprivate final func createAttachment(
        url: URL, _ isMovie: Bool = false, image: UIImage? = nil) -> Attachment? {
        let fileExtension = url.pathExtension
        let baseName = NSLocalizedString(
            "Attachment",
            comment: "Base name for attachments, must be the same name iOS uses for NSHTMLTextDocumentType attachments")
        let fileName = attachmentCounter.filename(baseName: baseName, fileExtension: fileExtension)

        let mimeType = mimeTypeUtil?.getMimeType(fileExtension: fileExtension) ??
            MimeTypeUtil.defaultMimeType

        if let att = Attachment.inline(name: fileName, url: url, type: mimeType, image: image) {
            return att
        }
        return nil
    }

    fileprivate final func addContactSuggestTable() {
        suggestTableView = storyboard?.instantiateViewController(
            withIdentifier: "contactSuggestionTable").view as! SuggestTableView
        suggestTableView.delegate = self
        suggestTableView.hide()
        updateSuggestTable(defaultCellHeight, true)
        tableView.addSubview(suggestTableView)
    }

    fileprivate final func updateSuggestTable(_ position: CGFloat, _ start: Bool = false) {
        var pos = position
        if pos < defaultCellHeight && !start { pos = defaultCellHeight * (position + 1) + 2 }
        suggestTableView.frame.origin.y = pos
        suggestTableView.frame.size.height = tableView.bounds.size.height - pos + 2
    }

    fileprivate final func populateMessageForSending() -> Message? {
        let message = Message.create(uuid: MessageID.generate())

        allCells.forEach({ (cell) in
            if cell is RecipientCell, let fm = cell.fieldModel {
                let addresses = (cell as! RecipientCell).identities

                switch fm.type {
                case .to:
                    addresses.forEach({ (recipient) in
                        message.to.append(recipient)
                    })
                    break
                case .cc:
                    addresses.forEach({ (recipient) in
                        message.cc.append(recipient)
                    })
                    break
                case .bcc:
                    addresses.forEach({ (recipient) in
                        message.bcc.append(recipient)
                    })
                    break
                default: ()
                    break
                }
            } else if cell is MessageBodyCell {
                message.attachments = (cell as? MessageBodyCell)?.getAllAttachments() ?? []
                message.longMessageFormatted = cell.textView.toHtml()
                message.adaptLongImagesTextFormattedToAttachments()
                if message.attachments.isEmpty {
                    message.longMessage = cell.textView.text
                }
            } else if let fm = cell.fieldModel {
                switch fm.type {
                case .from:
                    message.from = (cell as? AccountCell)?.getIdentity()
                    break
                default:
                    message.shortMessage = cell.textView.text
                    break
                }
            }
        })

        if composeMode == .replyFrom || composeMode == .replyAll,
            let om = originalMessage {
            // According to https://cr.yp.to/immhf/thread.html
            var refs = om.references
            refs.append(om.messageID)
            if refs.count > 11 {
                refs.remove(at: 1)
            }
            message.references = refs
        }

        // determine the folder for this message
        let from = message.from ?? appConfig?.currentAccount?.user ?? Account.all()[0].user
        if let account = Account.by(address: from.address) {
            let f = Folder.by(account: account, folderType: .sent)
            message.parent = f
        } else {
            Log.warn(component: #function, content: "Cannot determine message account")
            return nil
        }

        return message
    }

    // MARK: - Public Methods

    public final func addMediaToCell() {
        let media = Capability.media

        media.request { (success, error) in
            self.imagePicker.delegate = self
            self.imagePicker.modalPresentationStyle = .currentContext
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary

            if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                self.imagePicker.mediaTypes = mediaTypes
            }

            GCD.onMain {
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        }
    }

    public final func addAttachment() {
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: ["public.data"], in: .import)
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(
        _ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let row = tableData?.getRow(at: indexPath.row) else {
            return UITableViewAutomaticDimension
        }
        return row.height
    }

    override func tableView(
        _ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let row = tableData?.getRow(at: indexPath.row) else {
            return UITableViewAutomaticDimension
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? ComposeCell else {
            return row.height
        }

        let height = cell.textView.fieldHeight
        let expandable = cell.fieldModel?.expanded

        if cell is AccountCell {
            if (cell as! AccountCell).shouldDisplayPicker {
                if (expandable != nil) && cell.isExpanded { return expandable! }
            }
        }

        if cell.fieldModel?.display == .conditional {
            if ccEnabled {
                if height <= row.height { return row.height }
                return height
            } else {
                return 0
            }
        }

        if height <= row.height {
            return row.height
        }

        return height
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData?.numberOfRows() ?? 0
    }

    override func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = tableData?.getRow(at: indexPath.row) else { return UITableViewCell() }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: row.identifier, for: indexPath) as! ComposeCell
        cell.updateCell(row, indexPath)
        cell.delegate = self

        if !allCells.contains(cell) {
            allCells.append(cell)
            if let rc = cell as? RecipientCell {
                updateInitialContent(recipientCell: rc)
            } else if let mc = cell as? MessageBodyCell {
                updateInitialContent(messageBodyCell: mc)
            } else if let fm = cell.fieldModel, fm.type == .subject {
                updateInitialContent(composeCell: cell)
            } else if let ac = cell as? AccountCell {
                self.origin = ac.accounts[0].user
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView is SuggestTableView {
            guard let cell = self.tableView.cellForRow(at: currentCell) as? RecipientCell else {
                return
            }
            if let identity = suggestTableView.didSelectIdentity(index: indexPath) {
                cell.addIdentity(identity)
                cell.textView.scrollToTop()
                self.tableView.updateSize()
            }
        }

        guard let cell = tableView.cellForRow(at: indexPath) as? ComposeCell else {
            return
        }
        if let accountCell = cell as? AccountCell {
            ccEnabled = accountCell.expand()
            self.tableView.updateSize()
        }
    }

    // MARK: - IBActions

    @IBAction func cancel() {
        let alertCtrl = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertCtrl.view.tintColor = .pEpGreen
        if let popoverPresentationController = alertCtrl.popoverPresentationController {
            popoverPresentationController.sourceView = view
        }

        alertCtrl.addAction(alertCtrl.action("MailComp.Action.Cancel", .cancel, {}))

        alertCtrl.addAction(alertCtrl.action("MailComp.Action.Delete", .destructive, {
            self.dismiss()
        }))

        alertCtrl.addAction(alertCtrl.action("MailComp.Action.Save", .default, {
            if let msg = self.populateMessageForSending(),
                let acc = msg.parent?.account, let f = Folder.by(account:acc, folderType: .drafts) {
                msg.parent = f
                msg.save()
            } else {
                Log.error(component: #function, errorString: "No drafts folder for message")
            }
            self.dismiss()
        }))

        present(alertCtrl, animated: true, completion: nil)
    }

    @IBAction func dismiss() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func send() {
        if let msg = populateMessageForSending() {
            msg.save()
        } else {
            Log.error(component: #function, errorString: "No message for sending")
        }
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Extensions

extension ComposeTableViewController: ComposeCellDelegate {
    
    public func haveToUpdateColor(newIdentity: [Identity], type: ComposeFieldModel) {
        switch type.type {
        case .to:
            destinyTo = newIdentity
        case .cc:
            destinyCc = newIdentity
        case .bcc:
            destinyBcc = newIdentity
        case .from:
            origin = newIdentity.last
        default:
            break
        }
        calculateComposeColor()
    }

    func calculateComposeColor() {
        if let to = destinyTo, let cc = destinyCc, let bcc = destinyBcc, let from = origin {
            var rating : PEP_rating?
            if let session = appConfig?.session {
                rating = PEPUtil.outgoingMessageColor(from: from, to: to,
                                                      cc: cc, bcc: bcc,
                                                      session: session)
            } else {
                rating = PEPUtil.outgoingMessageColor(from: from, to: to,
                                                      cc: cc, bcc: bcc)
            }
            if let rate = rating {
                showPepRating(pEpRating: rate)
            }
        }
    }

    func textdidStartEditing(at indexPath: IndexPath, textView: ComposeTextView) {}

    func textdidChange(at indexPath: IndexPath, textView: ComposeTextView) {
        let fModel = tableData?.rows.filter{ $0.type == textView.fieldModel?.type }
        fModel?.first?.value = textView.attributedText
        let suggestContacts = fModel?.first?.contactSuggestion ?? false

        currentCell = indexPath
        guard let cell = tableView.cellForRow(at: currentCell) as? ComposeCell else {
            tableView.updateSize()
            return
        }

        if suggestContacts {
            if suggestTableView.updateContacts(textView.text) {
                tableView.scrollToTopOf(cell)
                cell.textView.scrollToBottom()
                updateSuggestTable(CGFloat(indexPath.row))
            } else {
                cell.textView.scrollToTop()
                tableView.updateSize()
            }
        } else {
            tableView.updateSize()
        }
    }

    func textDidEndEditing(at indexPath: IndexPath, textView: ComposeTextView) {
        tableView.updateSize()
        suggestTableView.hide()
    }

    func textShouldReturn(at indexPath: IndexPath, textView: ComposeTextView) {}
}

// MARK: - RecipientCellDelegate

extension ComposeTableViewController: RecipientCellDelegate {

    func shouldOpenAddressbook(at indexPath: IndexPath) {
        currentCell = indexPath
        openAddressBook()
    }
}

// MARK: - MessageBodyCellDelegate

extension ComposeTableViewController: MessageBodyCellDelegate {

    func didStartEditing(at indexPath: IndexPath) {
        currentCell = indexPath
        let media = UIMenuItem(
            title: "MenuCtrl.Cameraroll".localized, action: #selector(addMediaToCell))
        let attachment = UIMenuItem(
            title: "MenuCtrl.Attachment".localized, action: #selector(addAttachment))
        menuController.menuItems = [media, attachment]
    }

    func didEndEditing(at indexPath: IndexPath) {
        menuController.menuItems?.removeAll()
    }
}

// MARK: - CNContactPickerViewController Delegate

extension ComposeTableViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        add(contact: contact)
    }

    func contactPicker(
        _ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        add(contact: contactProperty.contact, contactProperty: contactProperty)
    }

    /**
     The emails from contact are only traversed if `contactProperty` is nil.
     Otherwise, the email information is only used by `contactProperty`, which allows the
     user to select one and only one email for sending.
     */
    func add(contact: CNContact, contactProperty: CNContactProperty? = nil) {
        if let address = contactProperty?.value as? String {
            let partner = Identity.create(address: address, userID: contactProperty?.identifier)
            partner.userName = CNContactFormatter.string(
                from: contact, style: .fullName)
            add(identity: partner)
        } else {
            for emailLabel in contact.emailAddresses {
                let address = emailLabel.value as String
                let partner = Identity.create(address: address, userID: contact.identifier)
                partner.userName = CNContactFormatter.string(from: contact, style: .fullName)
                add(identity: partner)
            }
        }
        tableView.updateSize()
    }

    func add(identity: Identity) {
        identity.save()
        guard let cell = tableView.cellForRow(at: currentCell) as? RecipientCell else {
            return
        }
        cell.addIdentity(identity)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ComposeTableViewController: UIImagePickerControllerDelegate {
    public func imagePickerController(
        _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        guard let cell = tableView.cellForRow(at: currentCell) as? MessageBodyCell else { return }

        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            if mediaType == kUTTypeMovie as String {
                guard let url = info[UIImagePickerControllerMediaURL] as? URL else { return }
                if let attachment = createAttachment(url: url, true) {
                    cell.addMovie(attachment)
                }
            } else {
                guard let url = info[UIImagePickerControllerReferenceURL] as? URL else {
                    return
                }
                guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                    return
                }
                if let attachment = createAttachment(url: url, image: image) {
                    cell.insert(attachment)
                }
            }
        }

        tableView.updateSize()
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UIDocumentPickerDelegate

extension ComposeTableViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        guard let cell = tableView.cellForRow(at: currentCell) as? MessageBodyCell else { return }
        if let attachment = createAttachment(url: url) {
            cell.add(attachment)
        }
        tableView.updateSize()
    }
}

// MARK: - UINavigationControllerDelegate

extension ComposeTableViewController: UINavigationControllerDelegate {
}
