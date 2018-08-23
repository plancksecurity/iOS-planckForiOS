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

    /// Recipient to set as "To:".
    /// Is ignored if a originalMessage is set.
    var prefilledTo: Identity?
    /// Original message to compute content and recipients from (e.g. a message we reply to).
    var originalMessage: Message?
    var composeMode = ComposeUtil.ComposeMode.normal

    private var originalMessageIsDraft: Bool {
        var omIsDrafts = false
        if let om = originalMessage, om.parent.folderType == .drafts {
            omIsDrafts = true
        }
        return omIsDrafts
    }

    var accountPicker = UIPickerView()
    var pickerEmailAdresses = [String]()
    var accountCell: AccountCell?

    private var tookOverAttachmentsAlready = false

    private let contactPicker = CNContactPickerViewController()
    private let imagePicker = UIImagePickerController()
    private let menuController = UIMenuController.shared
    private var suggestTableView: SuggestTableView!
    private let composeSection = 0
    private let attachmentSection = 1
    lazy private var attachmentFileIOQueue = DispatchQueue(label:
        "net.pep-security.ComposeTableViewController.attachmentFileIOQueue",
                                                           qos: .userInitiated)
    private var tableDict: NSDictionary?
    private var composeData: ComposeDataSource? = nil
    private var nonInlinedAttachmentData = ComposeDataSource.AttachmentDataSource()
    private var currentCellIndexPath: IndexPath!
    private var allCells = MutableOrderedSet<ComposeCell>()
    private var cells = [ComposeFieldModel.FieldType:ComposeCell]()
    private var ccEnabled = false
    private var messageToSend: Message?
    private lazy var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private let mimeTypeController = MimeTypeUtil()
    private var origin : Identity?
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
    /**
     The `ComposeTextView`, if it currently owns the focus.
     */
    private var composeTextViewFirstResponder: ComposeTextView?
    /**
     Caching the last row heights, in case the cell goes out of visiblity.
     */
    private var rowHeightCache = [IndexPath:CGFloat]()
    /**
     Last time something changed, this was the rating of the message currently in edit.
     */
    private var currentRating = PEP_rating_undefined

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        registerXibs()
        addContactSuggestTable()
        prepareFields()
        addKeyboardObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        composeData?.filterRows(message: nil)
        takeOverAttachmentsIfRequired()
        setInitialStatus()
        rowHeightCache.removeAll()
        setupPickerView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setFirstResponder()
        calculateComposeColorAndInstallTapGesture()
    }

    func setupPickerView() {
        let accounts = Account.all()
        self.pickerEmailAdresses = accounts.map { $0.user.address }
        self.accountPicker.delegate = self
        self.accountPicker.dataSource = self
    }

    func shouldDisplayAccountCell() -> Bool {
        return pickerEmailAdresses.count > 1
    }

    deinit {
        removeObservers()
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
        origin = origin ?? ComposeUtil.initialFrom(composeMode: composeMode,
                                                   originalMessage: originalMessage)
        cell.textView.text = origin?.address
        cell.textView.inputView = accountPicker
    }

    /**
     Updates the given `RecipientCell` with available data, if this is a suitable `ComposeMode`.
     */
    private func updateInitialContent(recipientCell: RecipientCell) {
        guard let fm = recipientCell.fieldModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No model")
            return
        }
        var result = [Identity]()
        if let om = originalMessage {
            //            var result = [Identity]()
            switch fm.type {
            case .to:
                result = ComposeUtil.initialTos(composeMode: composeMode, originalMessage: om)
            case .cc:
                result = ComposeUtil.initialCcs(composeMode: composeMode, originalMessage: om)
            case .bcc:
                result =  ComposeUtil.initialBccs(composeMode: composeMode, originalMessage: om)
            default:
                return
            }
        } else if let to = prefilledTo, fm.type == .to {
            result = [to]
        } else {
            // There is no original message (e.g. in `normal`compose mode). It's OK.
            // Do nothing
        }
        for id in result {
            recipientCell.addIdentity(id)
        }
        if result.count > 0 && ( fm.type == .cc || fm.type == .bcc) {
            // CC and/or BCC has been set. Show it to the user
            ccEnabled = true
        }
    }

    private func setFirstResponder() {
        var toCell: RecipientCell?
        var bodyCell: MessageBodyCell?
        for cell in tableView.visibleCells {
            if let safeCell = cell as? RecipientCell,
                let model = safeCell.fieldModel,
                model.type == .to {
                toCell = safeCell
            } else if let safeCell = cell as? MessageBodyCell {
                bodyCell = safeCell
            } else {
                continue
            }
        }

        if destinyTo.count == 0 {
            toCell?.makeBecomeFirstResponder(inTableView: tableView)
        } else {
            bodyCell?.makeBecomeFirstResponder(inTableView: tableView)
        }
    }

    private func setInitialStatus() {
        destinyTo = [Identity]()
        destinyCc = [Identity]()
        destinyBcc = [Identity]()
        if let om = originalMessage {
            origin = ComposeUtil.initialFrom(composeMode: composeMode, originalMessage: om)
            destinyTo = ComposeUtil.initialTos(composeMode: composeMode, originalMessage: om)
            destinyCc = ComposeUtil.initialCcs(composeMode: composeMode, originalMessage: om)
            destinyBcc = ComposeUtil.initialBccs(composeMode: composeMode, originalMessage: om)


        } else if let to = prefilledTo {
            destinyTo = [to]
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
            messageBodyCell.setInitial(text: ReplyUtil.quotedMessageText(message: om,
                                                                         replyAll: true))
        case .forward:
            setBodyText(forMessage: om, to: messageBodyCell)
        case .normal:
            if originalMessageIsDraft {
                setBodyText(forMessage: om, to: messageBodyCell)
            }
            // do nothing.
        }
    }

    private func setBodyText(forMessage msg: Message, to cell: MessageBodyCell) {
        guard originalMessageIsDraft || composeMode == .forward else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "Unsupported mode or message")
            return
        }
        if let html = msg.longMessageFormatted {
            // We have HTML content. Parse it taking inlined attachments into account.
            let attributedString = html.htmlToAttributedString(attachmentDelegate: self)
            var result = attributedString
            if composeMode == .forward {
                // forwarded messges must have a cite header ("yxz wrote on ...")
                result = ReplyUtil.citedMessageText(textToCite: attributedString,
                                                           fromMessage: msg)
            }
            cell.setInitial(text:result)
        } else {
            // No HTML available.
            var result = msg.longMessage ?? ""
            if composeMode == .forward {
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
        case .normal:
            if om.parent.folderType == .drafts {
                subjectCell.setInitial(text: om.shortMessage ?? "")
            }
            // .normal is intentionally ignored here for other folder types
        }
    }

    private final func prepareFields()  {
        if let path = Bundle.main.path(forResource: "ComposeData", ofType: "plist") {
            tableDict = NSDictionary(contentsOfFile: path)
        }

        if let dict = tableDict as? [String: Any],
            let dictRows = dict["Rows"] as? [[String: Any]] {
            composeData = ComposeDataSource(with: dictRows)
        }
    }

    /// If appropriate for the current compose mode, it takes over attachments
    /// from original message.
    /// Does nothing otherwise
    private func takeOverAttachmentsIfRequired() {
        guard shouldTakeOverAttachments(), !tookOverAttachmentsAlready else {
            return // Nothing to do.
        }
        tookOverAttachmentsAlready = true
        guard let om = originalMessage else {
            Log.shared.errorAndCrash(
                component: #function,
                errorString:
                "We must take over attachments from original message, but original message is nil.")
            return
        }
        let nonInlinedAttachments = om.viewableAttachments().filter { $0.contentDisposition == .attachment }
        nonInlinedAttachmentData.add(attachments: nonInlinedAttachments)
    }

    /// Computes whether or not attachments must be taken over in current compose mode
    ///
    /// - Returns: true if we must take over attachments from the original message, false otherwize
    private func shouldTakeOverAttachments() -> Bool {
        return composeMode == .forward || originalMessageIsDraft
    }

    // MARK: - Address Suggstions

    private final func addContactSuggestTable() {
        suggestTableView = storyboard?.instantiateViewController(
            withIdentifier: "contactSuggestionTable").view as! SuggestTableView
        suggestTableView.delegate = self
        suggestTableView.hide()
        updateSuggestTable(defaultCellHeight, true)
        tableView.addSubview(suggestTableView)
    }

    private func assureSuggestionsAreNotHiddenBehindKeyboard(keyboardSize: CGSize) {
        let searchfieldHeight = defaultCellHeight
        let contentInset = UIEdgeInsets(top: 0,
                                        left: 0,
                                        bottom: keyboardSize.height + searchfieldHeight,
                                        right: 0)
        suggestTableView.contentInset = contentInset
        suggestTableView.scrollIndicatorInsets = contentInset
    }

    private func resetSuggestionsKeyboardOffset() {
        let zeroOffset = UIEdgeInsets()
        suggestTableView.contentInset = zeroOffset
        suggestTableView.scrollIndicatorInsets = zeroOffset
    }

    // MARK: - Composing Mail

    private final func updateSuggestTable(_ position: CGFloat, _ start: Bool = false) {
        var pos = position
        if pos < defaultCellHeight && !start { pos = defaultCellHeight * (position + 1) + 2 }
        suggestTableView.frame.origin.y = pos
        suggestTableView.frame.size.height = tableView.bounds.size.height - pos + 2
    }

    private final func populateMessageFromUserInput() -> Message? {
        let fromCells = allCells.filter { $0.fieldModel?.type == .from }
        guard fromCells.count == 1,
            let fromCell = fromCells.first,
            let fromAddress = (fromCell as? AccountCell)?.textView.text,
            let account = Account.by(address: fromAddress) else {
                Log.shared.errorAndCrash(
                    component: #function,
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
                    var longMessageFormatted = markdownText.markdownToHtml()
                    if let safeHtml = longMessageFormatted {
                        longMessageFormatted = wrappedInHtmlStyle(toWrap: safeHtml)
                    }
                    message.longMessageFormatted = longMessageFormatted
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
        message.setOriginalRatingHeader(rating: self.recalculateCurrentRating())

        return message
    }

    /// Wraps a given string in simple HTML to make the content look acceptable in on receiver side.
    /// Approached behavior:
    /// - newlines are not ignored
    /// - long lines with no linebrake are wraped instead of potentially break out of the parents container.
    /// - mimik responsive "scale to fit" behaviour for inlined images
    /// - Parameter toWrap: content to wrap
    /// - Returns: wrapped content
    private func wrappedInHtmlStyle(toWrap: String) -> String {
        let style =
        """
            img {
                max-width: 100%;
                height: auto;
            }
            div {
                white-space: pre-wrap;
            }
        """
        let prefixHtml =
        """
            <html>
                <head>
                    <style>
                        \(style)
                    </style>
                </head>
                <body>
                    <div>
        """
        let postfixHtml =
        """
                    </div>
                </body>
            </html>
        """
        return prefixHtml + toWrap + postfixHtml
    }

    private func recalculateCurrentRating() -> PEP_rating {
        let session = PEPSession()
        if let from = self.origin {
            currentRating = session.outgoingMessageRating(from: from,
                                                          to: self.destinyTo,
                                                          cc: self.destinyCc,
                                                          bcc: self.destinyBcc)
        } else {
            currentRating = PEP_rating_undefined
        }
        return currentRating
    }

    private func handshakeActionCombinations() -> [HandshakeCombination] {
        if let from = self.origin {
            var allIdenties = destinyTo
            allIdenties.append(from)
            allIdenties.append(contentsOf: destinyCc)
            allIdenties.append(contentsOf: destinyBcc)
            return Message.handshakeActionCombinations(identities: allIdenties)
        } else {
            return []
        }
    }

    private func canHandshake() -> Bool {
        return !handshakeActionCombinations().isEmpty
    }

    private func canToggleProtection() -> Bool {
        let outgoingRatingColor = currentRating.pEpColor()
        return outgoingRatingColor == PEP_color_yellow || outgoingRatingColor == PEP_color_green
    }

    private func calculateComposeColorAndInstallTapGesture() {
        DispatchQueue.main.async { [weak self] in
            if let theSelf = self {
                let ratingValue = theSelf.recalculateCurrentRating()
                if let view = theSelf.showPepRating(pEpRating: ratingValue,
                                                    pEpProtection: theSelf.pEpProtection) {
                    if theSelf.canHandshake() || theSelf.canToggleProtection() {
                        let tapGestureRecognizer = UITapGestureRecognizer(
                            target: theSelf,
                            action: #selector(theSelf.actionHandshakeOrForceUnprotected))
                        view.addGestureRecognizer(tapGestureRecognizer)
                    }
                }
            }
        }
    }

    // MARK: - Attachments

    @objc private final func addMediaToCell() {
        let media = Capability.media
        media.requestAndInformUserInErrorCase(viewController: self)  {
            (permissionsGranted: Bool, error: Capability.AccessError?) in
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
    private final func addAttachment() {
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
    private final func createAttachment(forAssetWithUrl assetUrl: URL,
                                            image: UIImage) -> Attachment {
        let mimeType = assetUrl.mimeType() ?? MimeTypeUtil.defaultMimeType
        let attachment = Attachment.createFromAsset(mimeType: mimeType,
                                                    assetUrl: assetUrl,
                                                    image: image,
                                                    contentDisposition: .inline)
        return attachment
    }

    /// Used to create an Attachment from files that are not a security scoped resource.
    /// E.g. videos provided by UIImagePicker
    ///
    /// - Parameters:
    ///   - resourceUrl: URL of the resource to create an attachment for
    /// - Returns: attachment for given resource
    private final func createAttachment(forResource resourceUrl: URL,
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
                                                fileName: filename,
                                                contentDisposition: .attachment)
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
    private final func createAttachment(forSecurityScopedResource resourceUrl: URL,
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
                                               fileName: filename,
                                               contentDisposition: .attachment)
            completion(attachment)
        }
    }

    private func inline(image: UIImage, forMediaWithInfo info: [String: Any]) {
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

    private func attachVideo(forMediaWithInfo info: [String: Any]) {
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

    /**
     For cache* functions (row height cache), checks the preconditions
     - Returns: A height if the caller should return asap, or nil if own logic should
     be applied.
     */
    func cachePreconditions(height: CGFloat, indexPath: IndexPath) -> CGFloat? {
        assert(indexPath.section == composeSection)
        if indexPath.section != composeSection {
            return height
        }
        return nil
    }

    /**
     Caches the given height for the given indexPath.
     - Returns: The given height.
     */
    func caching(height: CGFloat, indexPath: IndexPath) -> CGFloat {
        if let h = cachePreconditions(height: height, indexPath: indexPath) {
            return h
        }
        rowHeightCache[indexPath] = height
        return height
    }

    /**
     - Returns: The cached height for the given indexPath, or the given one.
     */
    func cached(height: CGFloat, indexPath: IndexPath) -> CGFloat {
        if let h = cachePreconditions(height: height, indexPath: indexPath) {
            return h
        }
        return rowHeightCache[indexPath] ?? height
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
            // The cell might have gone out of visiblity, in which case the table will
            // not return it. Try to use a cached value then.
            return cached(height: row.height, indexPath: indexPath)
        }

        let height = cell.textView.fieldHeight
            if cell is AccountCell, self.shouldDisplayAccountCell() {
                return height
        }

        if let tempCell = cell as? RecipientCell{
            tempCell.ccEnabled = ccEnabled
        }
        
        if cell.fieldModel?.display == .conditional {
            if cell.shouldDisplay() {
                if height <= row.height {
                    return caching(height: row.height, indexPath: indexPath)
                }
                return caching(height: height, indexPath: indexPath)
            } else {
                return caching(height: 0, indexPath: indexPath)
            }
        }

        if height < row.height {
            return row.height
        }

        return caching(height: height, indexPath: indexPath)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.isEqual(suggestTableView) {
            return suggestTableView.numberOfRows(inSection: section)
        }
        switch section {
        case composeSection:
            return composeData?.numberOfRows() ?? 0
        case attachmentSection:
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
                let c = tableView.dequeueReusableCell(withIdentifier: row.identifier,
                                                      for: indexPath) as? ComposeCell
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
                    self.accountCell = ac
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

        return returnee
    }

    // MARK: - TableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView is SuggestTableView {
            guard let cell = self.tableView.cellForRow(
                at: currentCellIndexPath) as? RecipientCell else {
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
        if let recipientCell = cell as? WrappedCell {
            ccEnabled = recipientCell.expand()
            recipientCell.ccEnabled = ccEnabled
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

    private func configure(action: SwipeAction, with descriptor: SwipeActionDescriptor) {
        action.title = NSLocalizedString("Remove", comment:
            "ComposeTableView: Label of swipe left. Removing of attachment."
        )
        action.backgroundColor = descriptor.color
    }

    // MARK: - Other

    private func registerXibs() {
        let nib = UINib(nibName: AttachmentCell.storyboardID, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: AttachmentCell.storyboardID)
    }

    private func saveDraft() {
        if originalMessageIsDraft {
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
        om.imapMarkDeleted()
    }

    // MARK: - UIAlertController

    private func deleteAction(forAlertController ac: UIAlertController) -> UIAlertAction {
        let action: UIAlertAction
        let text: String
        if originalMessageIsDraft {
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
        if originalMessageIsDraft {
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

    private func showAlertControllerWithOptionsForCanceling(sender: Any) {
        let alertCtrl = UIAlertController.pEpAlertController(preferredStyle: .actionSheet)
        if let popoverPresentationController = alertCtrl.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender as? UIBarButtonItem
        }
        alertCtrl.addAction(
            alertCtrl.action(
                NSLocalizedString("Cancel",
                                  comment: "compose email cancel"),
                .cancel))
        alertCtrl.addAction(deleteAction(forAlertController: alertCtrl))
        alertCtrl.addAction(saveAction(forAlertController: alertCtrl))

        present(alertCtrl, animated: true, completion: nil)
    }

    // MARK: - IBActions

    @IBAction func cancel(_ sender: Any) {
        if edited {
            showAlertControllerWithOptionsForCanceling(sender: sender)
        } else {
            dismiss()
        }
    }

    func dismiss() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func send() {
        if let invalidRecipients = invalidReceipients() {
            informUser(invalidRecipients: invalidRecipients)
            return
        }
        guard let msg = populateMessageFromUserInput() else {
            Log.error(component: #function, errorString: "No message for sending")
            dismiss(animated: true, completion: nil)
            return
        }
        guard !msg.allRecipients.isEmpty else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString:
                "Should never be reached. Send button should be greyed out in this case")
            return
        }
        msg.save()
        if originalMessageIsDraft {
            // From user perspective, we have edited a drafted message and will send it.
            // Technically we are creating and sending a new message (msg), thus we have to
            // delete the original, previously drafted one.
            deleteOriginalMessage()
        }
        dismiss(animated: true, completion: nil)
    }

    // MARK: - KeyboardObserver

    private func addKeyboardObservers() {
        // Show Keyboard Observer
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.UIKeyboardDidShow, object: nil,
            queue: OperationQueue.main) { [weak self] notification in
                self?.keyboardDidShow(notification: notification)
        }
        // Hide Keyboard Observer
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil,
                                               queue: OperationQueue.main) {
                                                [weak self] notification in
                                                self?.keyboardDidHide()
        }
    }

    func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    private func keyboardDidShow(notification: Notification) {
        if let composeView = composeTextViewFirstResponder {
            Timer.scheduledTimer(timeInterval: 0.1,
                                 target: self,
                                 selector: #selector(self.scrollToMessageBodyCaretOnTimer),
                                 userInfo: composeView,
                                 repeats: false)
            scrollToMessageBodyCaret(composeTextView: composeView)
        }

        // Suggestion Tableview
        if let keyboardSize =
            (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect)?.size {
            assureSuggestionsAreNotHiddenBehindKeyboard(keyboardSize: keyboardSize)
        }
    }

    private func keyboardDidHide() {
        resetSuggestionsKeyboardOffset()
    }

    @objc func scrollToMessageBodyCaretOnTimer(_ timer: Timer) {
        if let composeView = timer.userInfo as? ComposeTextView {
            self.scrollToMessageBodyCaret(composeTextView: composeView)
        }
    }
    func scrollToMessageBodyCaret(composeTextView: ComposeTextView) {
        composeTextView.scrollCaretToVisible(tableView: tableView)
    }
}

// MARK: - ComposeCellDelegate

extension ComposeTableViewController: ComposeCellDelegate {
    func composeCell(cell: ComposeCell, didChangeEmailAddresses changedAddresses: [String],
                     forFieldType type: ComposeFieldModel.FieldType) {
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
        calculateComposeColorAndInstallTapGesture()
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
        calculateComposeColorAndInstallTapGesture()
    }

    /**
     Shows a menu where user can choose to make a handshake, or toggle force unprotected.
     */
    @IBAction func actionHandshakeOrForceUnprotected(gestureRecognizer: UITapGestureRecognizer) {
        let theCanHandshake = canHandshake()
        let theCanToggleProtection = canToggleProtection()

        if theCanHandshake || theCanToggleProtection {
            let alert = UIAlertController.pEpAlertController()

            if theCanHandshake {
                let actionReply = UIAlertAction(
                    title: NSLocalizedString("Handshake",
                                             comment: "possible privacy status action"),
                    style: .default) { [weak self] (action) in
                        self?.performSegue(withIdentifier: .segueHandshake, sender: self)
                }
                alert.addAction(actionReply)
            }

            if theCanToggleProtection {
                let originalValueOfProtection = pEpProtection
                let title = pEpProtection ?
                    NSLocalizedString("Disable Protection",
                                      comment: "possible private status action") :
                    NSLocalizedString("Enable Protection",
                                      comment: "possible private status action")
                let actionToggleProtection = UIAlertAction(
                    title: title,
                    style: .default) { [weak self] (action) in
                        self?.pEpProtection = !originalValueOfProtection
                        self?.calculateComposeColorAndInstallTapGesture()
                }
                alert.addAction(actionToggleProtection)
            }

            let cancelAction = UIAlertAction(
                title: NSLocalizedString("Cancel", comment: "possible private status action"),
                style: .cancel) { (action) in }
            alert.addAction(cancelAction)

            present(alert, animated: true, completion: nil)
        }
    }

    func textDidStartEditing(at indexPath: IndexPath, textView: ComposeTextView) {
    }

    func textDidChange(at indexPath: IndexPath, textView: ComposeTextView) {
        edited = true

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
        let cell = tableView.cellForRow(at: currentCellIndexPath)
        guard let composeCell = cell as? ComposeCell else {
            tableView.updateSize()
            return
        }

        if suggestContacts {
            if suggestTableView.updateContacts(textView.text) {
                tableView.scrollToTopOf(composeCell)
                composeCell.textView.scrollToBottom()
                updateSuggestTable(CGFloat(indexPath.row))
            } else {
                composeCell.textView.scrollToTop()
                tableView.updateSize()
            }
        } else {
            textView.layoutAfterTextDidChange(tableView: tableView)
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
    func didStartEditing(at indexPath: IndexPath, composeTextView: ComposeMessageBodyTextView) {
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

        composeTextViewFirstResponder = composeTextView
    }

    func didEndEditing(at indexPath: IndexPath, composeTextView: ComposeMessageBodyTextView) {
        menuController.menuItems?.removeAll()
        composeTextViewFirstResponder = nil
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
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
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

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
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
            if attachment.contentID == src?.extractCid() {
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

// MARK: - Address Validation

extension ComposeTableViewController {

    /// Checks all recipients addresses for validity and returns invalid ones.
    ///
    /// - Returns:  if any: all recipients with invalid e-mail addresses
    ///             nil otherwize
    private func invalidReceipients() -> [Identity]? {
        var invalidReceipients = [Identity]()
        for cell in allCells {
            if let tempCell = cell as? RecipientCell, let fm = cell.fieldModel {
                tempCell.generateContact(tempCell.textView)
                let addresses = (tempCell).identities
                switch fm.type {
                case .to, .cc, .bcc:
                    addresses.forEach({ (recipient) in
                        if !recipient.address.isProbablyValidEmail() {
                            invalidReceipients.append(recipient)
                        }
                    })
                default:
                    break
                }
            }
        }
        return invalidReceipients.count > 0 ? invalidReceipients : nil
    }

    /// Inform user: He entered invalid email addresses.
    ///
    /// - Parameter invalidRecipients: recipients with invalid email address
    private func informUser(invalidRecipients: [Identity]) {
        let title = NSLocalizedString("Invalid Address",
                                      comment:
            "Compose view-invalid email address - Alert Title for invalid recipient address(es)")
        let addressesString = invalidRecipients.reduce("") { (result, recipient) -> String in
            if result == "" {
                return recipient.address
            } else {
                return result + ", " + recipient.address
            }
        }
        let message = NSLocalizedString(
            "\(invalidRecipients.count == 1 ? "This address is" : "Those addresses are") not valid: \n\(addressesString)",
            comment: "Compose view-invalid email address - Alert body for invalid recipient address(es)")
        UIUtils.showAlertWithOnlyPositiveButton(title: title,
                                                message: message,
                                                inViewController: self)
    }
}

 //pickerView extension

 extension ComposeTableViewController: UIPickerViewDelegate, UIPickerViewDataSource  {

    // MARK: - UIPickerView Delegate & Datasource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerEmailAdresses.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerEmailAdresses[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let address = pickerEmailAdresses[row]
        self.accountCell?.setAccount(address: address)
    }


 }
