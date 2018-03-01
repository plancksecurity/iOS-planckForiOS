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
import SwipeCellKit
import Photos

class ComposeTableViewController: BaseTableViewController {
    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet var sendButton: UIBarButtonItem!

    enum ComposeMode {
        case normal
        case replyFrom
        case replyAll
        case forward
        case draft
    }

    private let contactPicker = CNContactPickerViewController()
    private let imagePicker = UIImagePickerController()
    private let menuController = UIMenuController.shared

    private var suggestTableView: SuggestTableView!
    private let composeSection = 0
    private let attachmentSection = 1
    lazy private var attachmentFileIOQueue = DispatchQueue(label: "net.pep-security.ComposeTableViewController.attachmentFileIOQueue",
                                                           qos: .userInitiated)
    private var tableDict: NSDictionary?
    private var composeData: ComposeDataSource? = nil
    private var nonInlinedAttachmentData = ComposeDataSource.AttachmentDataSource()
    private var currentCellIndexPath: IndexPath!
    private var allCells = MutableOrderedSet<ComposeCell>()
    private var cells = [ComposeFieldModel.FieldType:ComposeCell]()
    private var ccEnabled = false

    var rating : String = ""

    var composeMode: ComposeMode = .normal
    private var messageToSend: Message?
    var originalMessage: Message?
    private let operationQueue = OperationQueue()

    private lazy var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    private let mimeTypeController = MimeTypeUtil()

    var origin : Identity?
    private var destinyTo = [Identity]()
    private var destinyCc = [Identity]()
    private var destinyBcc = [Identity]()

    private let attachmentCounter = AttachmentCounter()
    private let mimeTypeUtil = MimeTypeUtil()


    private var edited = false

    /**
     A value of `true` means that the mail will be encrypted.
     */
    private var pEpProtection = true

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        registerXibs()
        addContactSuggestTable()
        prepareFields()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        composeData?.filterRows(message: nil)
        setEmailDisplayDefaultNavigationBarStyle()
        takeOverAttachmentsIfRequired()
        setInitialSendButtonStatus()
    }

    // MARK: - Setup & Configuration

    private func setup(_ cell: AttachmentCell, for indexPath: IndexPath) {
        guard
            indexPath.section == 1,
            let rowData = nonInlinedAttachmentData[indexPath.row] else {
                Log.shared.errorAndCrash(component: #function, errorString: "No data")
                return
        }
        cell.delegate = self
        cell.fileName.text = rowData.fileName
        cell.fileExtension.text = rowData.fileExtesion
    }

    private func setup(_ cell: AccountCell) {
        let accounts = Account.all()
        origin = origin ?? Account.defaultAccount()?.user
        cell.textView.text = origin?.address
        cell.pickerEmailAdresses = accounts.map { $0.user.address }
        cell.picker.reloadAllComponents()
    }

    /**
     Updates the given `RecipientCell` with data from the `originalMessage`,
     if this is a suitable `ComposeMode`.
     */
    private func updateInitialContent(recipientCell: RecipientCell) {
        if let fm = recipientCell.fieldModel, let om = originalMessage {
            switch fm.type {
            case .to:
                if composeMode == .replyFrom, let from = om.from {
                    recipientCell.addIdentity(from)
                } else if composeMode == .replyAll, let from = om.from {
                    let to = om.to
                    for identity in to {
                        recipientCell.addIdentity(identity)
                    }
                    recipientCell.addIdentity(from)
                } else if composeMode == .draft {
                    for ident in om.to {
                        recipientCell.addIdentity(ident)
                    }
                }
            case .cc:
                if composeMode == .replyAll || composeMode == .draft {
                    for ident in om.cc {
                        recipientCell.addIdentity(ident)
                    }
                }
            case .bcc:
                if composeMode == .replyAll  || composeMode == .draft {
                    for ident in om.bcc {
                        recipientCell.addIdentity(ident)
                    }
                }
            default:
                break
            }
        }
    }

    private func setInitialSendButtonStatus() {
        destinyTo = [Identity]()
        destinyCc = [Identity]()
        destinyBcc = [Identity]()
        guard let om = originalMessage else {
            // Nothing to do.
            // We have no original message, thus recipient fileds must be empty,
            // thus we can not send the mail and.
            return
        }
        origin = om.parent.account.user
        switch composeMode {
        case .replyFrom:
            if let from = om.from {
                destinyTo.append(from)
            }
        case .replyAll:
            if let from = om.from {
                destinyTo.append(from)
            }
            let to = om.to
            for id in to {
                if !id.isMySelf {
                    destinyTo.append(id)
                }
            }
            for id in om.cc {
                destinyCc.append(id)
            }
        case .normal:
            // Do nothing, has no recipient by definition, can not be send.
            break
        case .forward:
            // Do nothing. A initial forwarded message has no recipient by definition and thus
            // can not be send.
            break
        case .draft:
            for id in om.to {
                destinyTo.append(id)
            }
            for id in om.cc {
                destinyCc.append(id)
            }
            for id in om.bcc {
                destinyBcc.append(id)
            }
        }

        if (!destinyCc.isEmpty || !destinyTo.isEmpty || !destinyBcc.isEmpty) {
            messageCanBeSend(value: true)
        }
    }

    private func updateInitialContent(messageBodyCell: MessageBodyCell) {
        guard let om = originalMessage else {
            // We have no original message. That's OK for compose mode .normal.
            return
        }

        switch composeMode {
        case .replyFrom:
            messageBodyCell.setInitial(text: ReplyUtil.quotedMessageText(message: om,
                                                                         replyAll: false))
        case .replyAll:
            messageBodyCell.setInitial(
                text: ReplyUtil.quotedMessageText(message: om, replyAll: true))
        case .forward:
            setBodyText(forMessage: om, to: messageBodyCell, composeMode: .forward)
        case .draft:
            setBodyText(forMessage: om, to: messageBodyCell, composeMode: .draft)
        case .normal: fallthrough// do nothing.
        default:
            guard composeMode == .normal else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString:
                    """
.normal is the only compose mode that is intentionally ignored here
""")
                return
            }
        }
    }

    private func setBodyText(forMessage msg: Message, to cell: MessageBodyCell,
                             composeMode mode: ComposeMode) {
        guard mode == .draft || mode == .forward else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "Compose mode \(mode) is not supported")
            return
        }
        if let html = msg.longMessageFormatted {
            // We have HTML content. Parse it taking inlined attachments into account.
            let attributedString = html.htmlToAttributedString(attachmentDelegate: self)
            var result = attributedString
            if mode == .forward {
                // forwarded messges must have a cite header ("yxz wrote on ...")
                result = ReplyUtil.citedMessageText(textToCite: attributedString,
                                                           fromMessage: msg)
            }
            cell.setInitial(text:result)
        } else {
            // No HTML available.
            var result = msg.longMessage ?? ""
            if mode == .forward {
                // forwarded messges must have a cite header ("yxz wrote on ...")
                result = ReplyUtil.citedMessageText(textToCite: msg.longMessage ?? "",
                                           fromMessage: msg)
            }
            cell.setInitial(text: result)
        }
    }

    private func updateInitialContent(subjectCell: ComposeCell) {
        guard let om = originalMessage else {
            // We have no original message. That's OK for compose mode .normal.
            return
        }
        switch composeMode {
        case .replyFrom,
             .replyAll:
            subjectCell.setInitial(text: ReplyUtil.replySubject(message: om))
        case .forward:
            subjectCell.setInitial(text: ReplyUtil.forwardSubject(message: om))
        case .draft:
            subjectCell.setInitial(text: om.shortMessage ?? "")
        case .normal: fallthrough// do nothing.
        default:
            guard composeMode == .normal else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString:
                    """
.normal is the only compose mode that is intentionally ignored here
""")
                return
            }
        }
    }

    private final func prepareFields()  {
        if let path = Bundle.main.path(forResource: "ComposeData", ofType: "plist") {
            tableDict = NSDictionary(contentsOfFile: path)
        }

        if let dict = tableDict as? [String: Any], let dictRows = dict["Rows"] as? [[String: Any]]{
            composeData = ComposeDataSource(with: dictRows)
        }
    }

    /// If appropriate for the current compose mode, it takes over attachments
    /// from original message.
    /// Does nothing otherwise
    private func takeOverAttachmentsIfRequired() {
        guard shouldTakeOverAttachments() else {
            return // Nothing to do.
        }
        guard let om = originalMessage else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString:
                "We must take over attachments from original message, but original message is nil.")
            return
        }
        nonInlinedAttachmentData.add(attachments: om.viewableAttachments())
    }

    /// Computes whether or not attachments must be taken over in current compose mode
    ///
    /// - Returns: true if we must take over attachments from the original message, false otherwize
    private func shouldTakeOverAttachments() -> Bool {
        return composeMode == .forward || composeMode == .draft
    }

    // MARK: - Address Suggstions

    fileprivate final func addContactSuggestTable() {
        suggestTableView = storyboard?.instantiateViewController(
            withIdentifier: "contactSuggestionTable").view as! SuggestTableView
        suggestTableView.delegate = self
        suggestTableView.hide()
        updateSuggestTable(defaultCellHeight, true)
        tableView.addSubview(suggestTableView)
    }

    // MARK: - Composing Mail

    fileprivate final func updateSuggestTable(_ position: CGFloat, _ start: Bool = false) {
        var pos = position
        if pos < defaultCellHeight && !start { pos = defaultCellHeight * (position + 1) + 2 }
        suggestTableView.frame.origin.y = pos
        suggestTableView.frame.size.height = tableView.bounds.size.height - pos + 2
    }

    fileprivate final func populateMessageFromUserInput() -> Message? {
        let fromCells = allCells.filter { $0.fieldModel?.type == .from }
        guard fromCells.count == 1,
            let fromCell = fromCells.first,
            let fromAddress = (fromCell as? AccountCell)?.textView.text,
            let account = Account.by(address: fromAddress) else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "We have a problem here getting the senders account.")
                return nil
        }
        guard let f = Folder.by(account: account, folderType: .sent) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "No sent folder exists.")
            return nil
        }
        let message = Message(uuid: MessageID.generate(), parentFolder: f)

        allCells.forEach() { (cell) in
            if let tempCell = cell as? RecipientCell, let fm = cell.fieldModel {
                tempCell.generateContact(tempCell.textView)
                let addresses = (tempCell).identities

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
            } else if let bodyCell = cell as? MessageBodyCell {
                let inlinedAttachments = bodyCell.allInlinedAttachments()
                // add non-inlined attachments to our message ...
                message.attachments = nonInlinedAttachmentData.attachments

                if inlinedAttachments.count > 0 {
                    // ... and also inlined ones, parsed from the text.
                    // This can only work fro images. I case we decide to inline generic file icons,
                    // movie thumbnails or such, we have to re-think and re-write the code for
                    // inlined attachments, as for instance only the movies thumbnail would be send
                    // instead of the movie itself.
                    let (markdownText, attachments) = cell.textView.toMarkdown()
                    message.longMessage = markdownText
                    message.longMessageFormatted = markdownText.markdownToHtml()
                    message.attachments = message.attachments + attachments
                } else {
                    message.longMessage = cell.textView.text
                }
            } else if let fm = cell.fieldModel {
                switch fm.type {
                case .from:
                    message.from = account.user
                    break
                default:
                    message.shortMessage = cell.textView.text.trimmingCharacters(
                        in: .whitespacesAndNewlines).replaceNewLinesWith(" ")
                    break
                }
            }
        }

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

        message.pEpProtected = pEpProtection

        return message
    }

    fileprivate func calculateComposeColor() {
        DispatchQueue.main.async {
            if let from = self.origin {
                let session = PEPSession()
                let ratingValue = PEPUtil.outgoingMessageColor(from: from,
                                                          to: self.destinyTo,
                                                          cc: self.destinyCc,
                                                          bcc: self.destinyBcc,
                                                          session: session)
                self.rating = session.string(from: ratingValue)
                if let b = self.showPepRating(pEpRating: ratingValue, pEpProtection: self.pEpProtection) {
                    if ratingValue == PEP_rating_reliable || ratingValue == PEP_rating_trusted {
                        // disable protection only for certain ratings
                        let long = UILongPressGestureRecognizer(target: self,
                                                                action: #selector(self.toggleProtection))
                        b.addGestureRecognizer(long)
                    }
                    let tap = UITapGestureRecognizer(target: self, action: #selector(self.handshakeView))
                    b.addGestureRecognizer(tap)
                }
            }
        }
    }

    // MARK: - Attachments

    @objc fileprivate final func addMediaToCell() {
        let media = Capability.media
        media.requestAndInformUserInErrorCase(viewController: self)  { (permissionsGranted: Bool, error: Capability.AccessError?) in
            guard permissionsGranted else {
                return
            }
            self.imagePicker.delegate = self
            self.imagePicker.modalPresentationStyle = .currentContext
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary

            if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                self.imagePicker.mediaTypes = mediaTypes
            }
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }

    @objc // required for using it in #selector()
    fileprivate final func addAttachment() {
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: ["public.data"], in: .import)
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }

    /// Used to create an Attachment from images provided by UIImagePicker
    ///
    /// - Parameters:
    ///   - assetUrl: URL of the asset
    ///   - image: image to create attachment for
    /// - Returns: attachment for given image
    fileprivate final func createAttachment(forAssetWithUrl assetUrl: URL,
                                            image: UIImage) -> Attachment {
        let mimeType = assetUrl.mimeType() ?? MimeTypeUtil.defaultMimeType
        let attachment = Attachment.createFromAsset(mimeType: mimeType,
                                                    assetUrl: assetUrl,
                                                    image: image)
        return attachment
    }

    /// Used to create an Attachment from files that are not a security scoped resource.
    /// E.g. videos provided by UIImagePicker
    ///
    /// - Parameters:
    ///   - resourceUrl: URL of the resource to create an attachment for
    /// - Returns: attachment for given resource
    fileprivate final func createAttachment(forResource resourceUrl: URL,
                                            completion: @escaping (Attachment?) -> Void) {
        attachmentFileIOQueue.async {
            guard let resourceData = try? Data(contentsOf: resourceUrl) else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "Cound not get data for URL")
                completion(nil)
                return
            }

            let mimeType = resourceUrl.mimeType() ?? MimeTypeUtil.defaultMimeType
            let filename = self.fileName(forVideoAt: resourceUrl)
            let attachment =  Attachment.create(data: resourceData,
                                                mimeType: mimeType,
                                                fileName: filename)
            completion(attachment)
        }
    }

    private func fileName(forVideoAt url: URL) -> String {
        let fileName = NSLocalizedString("Video",
                                         comment:
            "File name used for videos the user attaches.")
        let numAttachment = nonInlinedAttachmentData.count() + 1
        let numDisplay = numAttachment > 1 ? " " + String(numAttachment) : ""
        let fileExtension = url.pathExtension
        return fileName + numDisplay + "." + fileExtension
    }

    /// Used to create an Attachment from security scoped resources.
    /// E.g. Documents provided by UIDocumentPicker
    ///
    /// - Parameters:
    ///   - resourceUrl: URL of the resource to create an attachment for
    /// - Returns: attachment for given resource
    fileprivate final func createAttachment(forSecurityScopedResource resourceUrl: URL,
                                            completion: @escaping (Attachment?) -> Void) {
        let cfUrl = resourceUrl as CFURL

        attachmentFileIOQueue.async {
            CFURLStartAccessingSecurityScopedResource(cfUrl)
            defer { CFURLStopAccessingSecurityScopedResource(cfUrl) }
            guard  let resourceData = try? Data(contentsOf: resourceUrl)  else {
                Log.shared.errorAndCrash(component: #function, errorString: "No data for URL.")
                completion(nil)
                return
            }
            let mimeType = resourceUrl.mimeType() ?? MimeTypeUtil.defaultMimeType
            let filename = resourceUrl.fileName(includingExtension: true)
            let attachment = Attachment.create(data: resourceData,
                                               mimeType: mimeType,
                                               fileName: filename)
            completion(attachment)
        }
    }

    fileprivate func inline(image: UIImage, forMediaWithInfo info: [String: Any]) {
        guard let cell = tableView.cellForRow(at: currentCellIndexPath) as? MessageBodyCell,
            let url = info[UIImagePickerControllerReferenceURL] as? URL
            else {
                Log.shared.errorAndCrash(component: #function, errorString: "Problem!")
                return
        }

        let attachment = createAttachment(forAssetWithUrl: url, image: image)
        cell.inline(attachment: attachment)
        self.tableView.updateSize()
    }

    fileprivate func attachVideo(forMediaWithInfo info: [String: Any]) {
        guard let url = info[UIImagePickerControllerMediaURL] as? URL else {
            Log.shared.errorAndCrash(component: #function, errorString: "Please check.")
            return
        }
        createAttachment(forResource: url) { (attachment: Attachment?) in
            guard let safeAttachment = attachment else {
                Log.shared.errorAndCrash(component: #function, errorString: "No attachment")
                return
            }
            GCD.onMain {
                self.addMovie(attachment: safeAttachment)
                self.tableView.updateSize()
            }
        }
    }

    func add(nonInlinedAttachment attachment: Attachment) {
        let indexInserted = nonInlinedAttachmentData.add(attachment: attachment)
        let indexPath = IndexPath(row: indexInserted, section: attachmentSection)
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }

    public final func addMovie(attachment: Attachment) {
        // We currently handle videos like any other attachment that is not an image.
        // Maybe we want to be able to play videos inlined later. See discussion in IOS-201.
        add(nonInlinedAttachment: attachment)
    }

    // MARK: - Table view data source

    override func tableView(
        _ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.isEqual(suggestTableView) || indexPath.section == attachmentSection {
            return UITableViewAutomaticDimension
        }
        guard let row = composeData?.getRow(at: indexPath.row) else {
            return UITableViewAutomaticDimension
        }
        return row.height
    }

    override func tableView(
        _ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.isEqual(suggestTableView) {
            return UITableViewAutomaticDimension
        }
        if indexPath.section == attachmentSection  {
            return AttachmentCell.preferredHigh
        }
        guard let row = composeData?.getRow(at: indexPath.row) else {
            return UITableViewAutomaticDimension
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? ComposeCell else {
            return row.height
        }

        let height = cell.textView.fieldHeight
        let expandable = cell.fieldModel?.expanded

        if let tempCell = cell as? AccountCell {
            if (tempCell).shouldDisplayPicker {
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
        if tableView.isEqual(suggestTableView) {
            return suggestTableView.numberOfRows(inSection: section)
        }
        switch section {
        case 0:
            return composeData?.numberOfRows() ?? 0
        case 1:
            return nonInlinedAttachmentData.count()
        default:
            Log.shared.errorAndCrash(component: #function, errorString: "Unhandled section")
            return 0
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        let composeCells = 1
        let attachmentCells = 1
        return composeCells + attachmentCells
    }

    override func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let returnee: UITableViewCell
        var cell: ComposeCell
        guard let row = composeData?.getRow(at: indexPath.row) else {
            Log.shared.errorAndCrash(component: #function, errorString: "Wrong data")
            return UITableViewCell()
        }
        if indexPath.section == composeSection {
            if let c = cells[row.type] {
                cell = c
            } else {
                guard
                let c = tableView.dequeueReusableCell(withIdentifier: row.identifier, for: indexPath) as? ComposeCell
                    else {
                        Log.shared.errorAndCrash(component: #function, errorString: "Wrong cell")
                        return UITableViewCell()
                }
                c.updateCell(row, indexPath)
                c.delegate = self
                cell = c
            }
            returnee = cell

            if !allCells.contains(cell) {
                allCells.append(cell)
                if let rc = cell as? RecipientCell, let type = rc.fieldModel?.type {
                    updateInitialContent(recipientCell: rc)
                    cells[type] = rc
                } else if let mc = cell as? MessageBodyCell, let type = mc.fieldModel?.type {
                    updateInitialContent(messageBodyCell: mc)
                    cells[type] = mc
                } else if let fm = cell.fieldModel, fm.type == .subject {
                    updateInitialContent(subjectCell: cell)
                    cells[fm.type] = cell
                } else if let ac = cell as? AccountCell, let type = ac.fieldModel?.type {
                    setup(ac)
                    cells[type] = ac
                }
            }
        } else if indexPath.section == attachmentSection {
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: AttachmentCell.storyboardID) as? AttachmentCell
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Wrong cell")
                    return UITableViewCell()
            }
            setup(cell, for: indexPath)
            returnee = cell
        } else {
            returnee = UITableViewCell()
        }

        if isRepresentingLastRow(indexpath: indexPath) {
            // Calculate color only once.
            calculateComposeColor()
        }

        return returnee
    }

    private func isRepresentingLastRow(indexpath: IndexPath) -> Bool {
        guard let numComposeRows = composeData?.numberOfRows() else {
            return false
        }
        let numAttachmentRows = nonInlinedAttachmentData.count()
        switch indexpath.section {
        case composeSection:
            if numAttachmentRows > 0 {
                // We have more rows in attachments section
                return false
            }
            return indexpath.row == max(0, numComposeRows - 1)
        case attachmentSection:
            return indexpath.row == max(0, numAttachmentRows - 1)
        default:
            Log.shared.errorAndCrash(component: #function, errorString: "Unhandled section")
            return true
        }
    }

    // MARK: - TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView is SuggestTableView {
            guard let cell = self.tableView.cellForRow(at: currentCellIndexPath) as? RecipientCell else {
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

    // MARK: - SwipeTableViewCell

    private func deleteAction(forCellAt indexPath: IndexPath) {
        guard indexPath.section == attachmentSection else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "only attachments have delete actions")
            return
        }
        nonInlinedAttachmentData.remove(at: indexPath.row)
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }

    private func configure(action: SwipeAction, with descriptor: ActionDescriptor) {
        action.title = NSLocalizedString("Remove", comment:
            """
ComposeTableView: Label of swipe left. Removing of attachment.
"""
        )
        action.backgroundColor = descriptor.color
    }

    // MARK: - Other

    private func registerXibs() {
        let nib = UINib(nibName: AttachmentCell.storyboardID, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: AttachmentCell.storyboardID)
    }

    private func saveDraft() {
        if self.composeMode == .draft {
            // We are in drafts folder and, from user perespective, are editing a drafted mail.
            // Technically we have to create a new one and delete the original message, as the
            // mail is already synced with the IMAP server and thus we must not modify it.
            self.deleteOriginalMessage()
        }

        if let msg = self.populateMessageFromUserInput() {
            let acc = msg.parent.account
            if let f = Folder.by(account:acc, folderType: .drafts) {
                msg.parent = f
                msg.imapFlags?.draft = true
                msg.save()
            }
        } else {
            Log.error(component: #function,
                      errorString: "No message")
        }
    }

    private func deleteOriginalMessage() {
        guard let om = originalMessage else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString:
                "We are currently editing a drafted mail but have no originalMessage?")
            return
        }
        // Make sure the "draft" flag is not set to avoid the original msg will keep in virtual
        // mailboxes, that show all flagged messages.
        om.imapFlags?.draft = false
        om.imapDeleteAndMarkTrashed()
    }

    // MARK: - UIAlertController

    private func deleteAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        let action: UIAlertAction
        let text: String
        if composeMode == .draft {
            text = NSLocalizedString("Discharge changes", comment:
                "ComposeTableView: button to decide to discharge changes made on a drafted mail.")
        } else {
            text = NSLocalizedString("Delete", comment: "compose email delete")
        }
        action = ac.action(text, .destructive) {
            self.dismiss()
        }
        return action
    }

    private func saveAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        let action: UIAlertAction
        let text:String
        if composeMode == .draft {
            text = NSLocalizedString("Save changes", comment:
                "ComposeTableView: button to decide to save changes made on a drafted mail.")
        } else {
            text = NSLocalizedString("Save", comment: "compose email save")
        }

        action = ac.action(text, .default) {
            self.saveDraft()
            self.dismiss()
        }
        return action
    }

    private func showAlertControllerWithOptionsForCanceling() {
        let alertCtrl = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertCtrl.view.tintColor = .pEpGreen
        if let popoverPresentationController = alertCtrl.popoverPresentationController {
            popoverPresentationController.sourceView = view
        }
        alertCtrl.addAction(alertCtrl.action(NSLocalizedString("Cancel",
                                                               comment: "compose email cancel"),
                                             .cancel,
                                             {}))
        alertCtrl.addAction(deleteAction(forAlertController: alertCtrl))
        alertCtrl.addAction(saveAction(forAlertController: alertCtrl))

        present(alertCtrl, animated: true, completion: nil)
    }

    // MARK: - IBActions

    @IBAction func cancel() {
        if edited {
            showAlertControllerWithOptionsForCanceling()
        } else {
            self.dismiss()
        }
    }

    @IBAction func dismiss() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func send() {
        defer {
            dismiss(animated: true, completion: nil)
        }
        guard let msg = populateMessageFromUserInput() else {
            Log.error(component: #function, errorString: "No message for sending")
            return
        }
        msg.save()
        if composeMode == .draft {
            // From user perspective, we have edited a drafted message and will send it.
            // Technically we are creating and sending a new message (msg), thus we have to
            // delete the original, previously drafted one.
            deleteOriginalMessage()
        }

    }
}

// MARK: - ComposeCellDelegate

extension ComposeTableViewController: ComposeCellDelegate {
    func composeCell(cell: ComposeCell, didChangeEmailAddresses changedAddresses: [String], forFieldType type: ComposeFieldModel.FieldType) {
        let identities = changedAddresses.map { Identity(address: $0) }
        switch type {
        case .to:
            destinyTo = identities
        case .cc:
            destinyCc = identities
        case .bcc:
            destinyBcc = identities
        case .from:
            origin = identities.last
        default:
            break
        }
        calculateComposeColor()
    }

    //remove after refactoring all Cells to not know Identity
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

    @IBAction func toggleProtection(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            pEpProtection = !pEpProtection
            calculateComposeColor()
        }
    }

    @IBAction func handshakeView(gestureRecognizer: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "segueHandshake", sender: nil)
    }

    func textdidStartEditing(at indexPath: IndexPath, textView: ComposeTextView) {
        self.edited = true
    }

    func textdidChange(at indexPath: IndexPath, textView: ComposeTextView) {
        guard indexPath.section == composeSection else {
            return
        }

        let models = composeData?.getVisibleRows().filter {
            $0.type == textView.fieldModel?.type
        }
        let modelFirst = models?.first
        modelFirst?.value = textView.attributedText
        let suggestContacts = modelFirst?.contactSuggestion ?? false

        currentCellIndexPath = indexPath
        guard let cell = tableView.cellForRow(at: currentCellIndexPath) as? ComposeCell else {
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

    func textShouldReturn(at indexPath: IndexPath, textView: ComposeTextView) {


    }

    func messageCanBeSend(value: Bool) {
        self.sendButton.isEnabled = value
    }
}

// MARK: - MessageBodyCellDelegate

extension ComposeTableViewController: MessageBodyCellDelegate {
    func didStartEditing(at indexPath: IndexPath) {
        self.edited = true
        currentCellIndexPath = indexPath
        let media = UIMenuItem(
            title: NSLocalizedString("Attach media",
                                     comment: "Attach photo/video (message text context menu)"),
            action: #selector(addMediaToCell))
        let attachment = UIMenuItem(
            title: NSLocalizedString("Attach file",
                                     comment: "Insert document in message text context menu"),
            action: #selector(addAttachment))
        menuController.menuItems = [media, attachment]
    }

    func didEndEditing(at indexPath: IndexPath) {
        menuController.menuItems?.removeAll()
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ComposeTableViewController: UIImagePickerControllerDelegate {
    public func imagePickerController( _ picker: UIImagePickerController,
                                       didFinishPickingMediaWithInfo info: [String: Any]) {
        defer { dismiss(animated: true, completion: nil) }
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // We got an image.
            inline(image: image, forMediaWithInfo: info)
        } else {
            // We got something from picker that is not an image. Probalby video/movie.
            attachVideo(forMediaWithInfo: info)
        }
    }


}

// MARK: - UIDocumentPickerDelegate

extension ComposeTableViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            createAttachment(forSecurityScopedResource: url) { (attachment: Attachment?) in

                guard let safeAttachment = attachment else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "No attachment")
                    return
                }
                GCD.onMain {
                    self.add(nonInlinedAttachment: safeAttachment)
                    self.tableView.updateSize()
                }
            }
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension ComposeTableViewController: UINavigationControllerDelegate {
    // We have to conform to UINavigationControllerDelegate to be ab le to set our self as
    // UIImagePickerController delegate, which is defined as
    // (UIImagePickerControllerDelegate & UINavigationControllerDelegate)?
}

// MARK: - SegueHandlerType

extension ComposeTableViewController: SegueHandlerType {

    enum SegueIdentifier: String {
        case segueHandshake
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .segueHandshake:
            guard let destination = segue.destination as? HandshakeViewController else {
                Log.shared.errorAndCrash(component: #function, errorString: "Segue issue")
                return
            }
            destination.appConfig = self.appConfig
            destination.message = populateMessageFromUserInput()
        }
    }

    @IBAction func segueUnwindAccountAdded(segue: UIStoryboardSegue) {
        // nothing to do.
    }
}

// MARK: - SwipeTableViewCellDelegate

extension ComposeTableViewController: SwipeTableViewCellDelegate {

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard indexPath.section == attachmentSection else {
            return nil
        }
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.deleteAction(forCellAt: indexPath)
        }
        configure(action: deleteAction, with: .trash)
        return (orientation == .right ?   [deleteAction] : nil)
    }
}

// MARK: - HtmlToAttributedTextSaxParserAttachmentDelegate

extension ComposeTableViewController: HtmlToAttributedTextSaxParserAttachmentDelegate {
    func imageAttachment(src: String?, alt: String?) -> Attachment? {
        guard let origAttachments = originalMessage?.attachments else {
            return nil
        }
        for attachment in origAttachments {
            if attachment.fileName?.extractCid() == src?.extractCid() {
                // The attachment is inlined.
                assertImage(inAttachment: attachment)
                // Remove from non-inlined attachments if contained.
                if let _ = nonInlinedAttachmentData.remove(attachment: attachment) {
                    // dataSource has changed. Refresh tableView.
                    tableView.reloadData()
                }

                return attachment
            }
        }
        return nil
    }

    private func assertImage(inAttachment attachment: Attachment) {
        // Assure the image is set ...
        if attachment.image == nil {
            guard let safeData = attachment.data else {
                Log.shared.errorAndCrash(component: #function, errorString: "No data")
                return
            }
            attachment.image = UIImage(data: safeData)
        }
        // ... and adjust its size.
        attachment.image = attachment.image?.resized(newWidth: tableView.contentSize.width)
    }
}
