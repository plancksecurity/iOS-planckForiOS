//
//  EmailViewModel.swift
//  pEp
//
//  Created by Martín Brude on 19/10/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import QuickLook.QLPreviewItem
import MessageModel
import pEpIOSToolbox

/// Delegate to comunicate with Email View.
protocol EmailViewModelDelegate: AnyObject {
    /// Show the item
    /// - Parameter quickLookItem: The quick look item to show. Could be the url of a document.
    func showQuickLookOfAttachment(quickLookItem: QLPreviewItem)
    /// Show Documents Editor
    /// - Parameter url: The url of the document
    func showDocumentsEditor(url: URL)
    /// Show Certificates Import View.
    /// - Parameter viewModel: The view model to setup the view.
    func showClientCertificateImport(viewModel: ClientCertificateImportViewModel)
    /// Shows the loading view
    func showLoadingView()
    /// Hides the loading view
    func hideLoadingView()
    /// Informs the viewModel is ready to provide external content.
    func showExternalContent()
}

//MARK: - EmailRowProtocol

protocol EmailRowProtocol {
    /// The cell identifier
    var cellIdentifier: String { get }
    var type: EmailViewModel.EmailRowType { get }
}

//MARK: - AttachmentRowProtocol

protocol AttachmentRowProtocol: EmailRowProtocol {
    var height: CGFloat { get }
    func retrieveAttachmentData(completion: (() -> Void)?)
    var filename: String { get }
    var fileExtension: String? { get }
    var icon: UIImage? { get }
    var isImage: Bool { get }
}

class EmailViewModel {

    /// Delegate to comunicate with Email View.
    public weak var delegate: EmailViewModelDelegate?
    private var rows: [EmailRowProtocol]
    private var message: Message

    /// Constructor
    /// - Parameter message: The message to display
    public init(message: Message, delegate: EmailViewModelDelegate? = nil) {
        self.message = message
        self.delegate = delegate
        self.rows = [EmailRowProtocol]()
        self.setupRows(message: message)
    }

    /// Retrieve a copy of itself. Does not keep the delegate.
    /// - Returns: The copy of instance
    public func copy() -> EmailViewModel {
        return EmailViewModel(message: message)
    }

    private var shouldHideExternalContent: Bool = true

    // Indicates if the External Content View has to be shown.
    public var shouldShowExternalContentView: Bool {
        guard let body = htmlBody else {
            return false
        }
        return body.containsExternalContent() && shouldHideExternalContent
    }

    // Yields the HTML message body if we can show it in a secure way or we have non-empty HTML content at all
    private var htmlBody: String? {
        guard let htmlBody = message.longMessageFormatted,
              !htmlBody.isEmpty else {
            return nil
        }

        func appendInlinedPlainText(fromAttachmentsIn message: Message, to text: String) -> String {
            var result = text
            let inlinedText = message.inlinedTextAttachments()
            for inlinedTextAttachment in inlinedText {
                guard let data = inlinedTextAttachment.data,
                      let inlinedText = String(data: data, encoding: .utf8) else {
                    continue
                }
                result = append(appendText: inlinedText, to: result)
            }
            return result
        }

        func append(appendText: String, to body: String) -> String {
            var result = body
            let replacee = result.contains(find: "</body>") ? "</body>" : "</html>"
            if result.contains(find: replacee) {
                result = result.replacingOccurrences(of: replacee, with: appendText + replacee)
            } else {
                result += "\n" + appendText
            }
            return result
        }
        return appendInlinedPlainText(fromAttachmentsIn: message, to: htmlBody)
    }

    /// Number of rows
    public var numberOfRows: Int {
        return rows.count
    }

    /// Retrieves the row
    subscript(index: Int) -> EmailRowProtocol {
        get {
            return rows[index]
        }
    }

    /// - Parameter indexPath: indexPath of the Cell.
    public func cellIdentifier(for indexPath: IndexPath) -> String {
        return rows[indexPath.row].cellIdentifier
    }

    /// Show external content.
    public func handleShowExternalContentButtonPressed() {
        shouldHideExternalContent = false
        delegate?.showExternalContent()
    }

    private func show(attachment: Attachment) {
        func shouldShowClientCertificate(url : URL) -> Bool {
            return url.pathExtension == "pEp12" || url.pathExtension == "pfx"
        }

        let defaultFileName = Attachment.defaultFilename
        attachment.saveToTmpDirectory(defaultFilename: attachment.fileName ?? defaultFileName) { [weak self] (url) in
            guard let url = url else {
                Log.shared.errorAndCrash("No Local URL")
                return
            }
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            DispatchQueue.main.async {
                me.delegate?.hideLoadingView()
                if shouldShowClientCertificate(url: url) {
                    let clientCertificate = ClientCertificateImportViewModel(certificateUrl: url)
                    me.delegate?.showClientCertificateImport(viewModel: clientCertificate)
                } else if QLPreviewController.canPreview(url as QLPreviewItem) {
                    me.delegate?.showQuickLookOfAttachment(quickLookItem: url as QLPreviewItem)
                } else {
                    me.delegate?.showDocumentsEditor(url: url)
                }
            }
        }
    }

    /// Handle the user tap gesture over the mail attachment
    /// - Parameter index: The index of the attachment
    public func handleDidTapAttachmentRow(at indexPath: IndexPath) {
        delegate?.showLoadingView()
        guard rows.count > indexPath.row else {
            Log.shared.errorAndCrash("attachment out of bounds")
            return
        }
        guard let row = rows[indexPath.row] as? BaseAttachmentRow else {
            Log.shared.errorAndCrash("Expected BaseAttachmentRow")
            return
        }
        show(attachment: row.attachment)
    }

    /// Handle the image has been loaded.
    /// - Parameters:
    ///   - indexPath: The indexPath of the cell that contains the image.
    ///   - height: The height of the image.
    public func handleImageFetched(forRowAt indexPath: IndexPath, withHeight height: CGFloat) {
        guard let row = rows[indexPath.row] as? ImageAttachmentRow else {
            Log.shared.errorAndCrash("Expected ImageAttachmentRow")
            return
        }
        let margin: CGFloat = 20.0
        row.height = height + margin
        rows[indexPath.row] = row
    }
}

//MARK: - Email Rows

extension EmailViewModel {

    // Represents a Recipient in the collection view.
    struct CollectionViewCellViewModel {

        public var size: CGSize {
            let recipientButton = RecipientButton(type: .system)
            recipientButton.setup(text: title, action: action)
            return recipientButton.frame.size
        }

        public private(set) var title: String
        public private(set) var identity: Identity?
        public private(set) var action: (() -> Void)?
        public private(set) var recipientType: EmailViewModel.RecipientType

        /// Constructor
        /// - Parameters:
        ///   - identity: The identity represented by the button
        ///   - action: The action to be executed
        init(identity: Identity?, recipientType: EmailViewModel.RecipientType, action: (() -> Void)? = nil) {
            self.identity = identity
            self.title = identity?.displayString ?? ""
            self.action = action
            self.recipientType = recipientType
        }

        /// Constructor
        /// - Parameter title: The title of the button
        init(title: String, recipientType: EmailViewModel.RecipientType, action: (() -> Void)? = nil) {
            self.recipientType = recipientType
            self.title = title
            self.action = action
        }
    }

    enum EmailRowType: String {
        case header, subject, body, attachment, imageAttachment
    }

    enum RecipientType: String {
        case from, to, cc, bcc
    }

    // MARK: Header

    struct HeaderRow: EmailRowProtocol {
        var type: EmailViewModel.EmailRowType = .header
        var cellIdentifier: String = "messageHeaderCell"
        var fromViewModel: CollectionViewCellViewModel
        var tosViewModels: [CollectionViewCellViewModel]
        var ccsViewModels: [CollectionViewCellViewModel]
        var bccsViewModels: [CollectionViewCellViewModel]
        var date: String?
        var image: UIImage?
        var viewModel: MessageHeaderCellViewModel
    }

    // MARK: Subject

    struct SubjectRow: EmailRowProtocol {
        var type: EmailViewModel.EmailRowType = .subject
        var cellIdentifier: String = "senderSubjectCell"
        var title: String
    }

    // MARK: Body

    struct BodyRow: EmailRowProtocol {
        var type: EmailViewModel.EmailRowType = .body
        public var cellIdentifier: String = "senderBodyCell"
        private var message: Message?
        public var htmlBody: String?

        /// Constructor
        ///
        /// - Parameters:
        ///   - htmlBody: The html body
        ///   - shouldShowExternalContentView: Indicates if should show the external content view
        ///   - message: The message.
        init(htmlBody: String?, message: Message? = nil) {
            self.htmlBody = htmlBody
            self.message = message
        }

        func body(completion: @escaping (NSMutableAttributedString) -> Void) {
            let finalText = NSMutableAttributedString()
            message?.pEpRating { (rating) in
                guard let message = message else {
                    let cantDecryptMessage = NSLocalizedString("This message could not be decrypted.",
                                                               comment: "content that is shown for undecryptable messages")
                    finalText.append(NSAttributedString.normalAttributedString(from: cantDecryptMessage))
                    return
                }
                if message.underAttack {
                    let status = String.pEpRatingTranslation(pEpRating: .underAttack)
                    let messageString = String.localizedStringWithFormat(
                        NSLocalizedString(
                            "\n%1$@\n\n%2$@\n\n%3$@\n\nAttachments are disabled.\n\n",
                            comment: "Disabled attachments for a message with status 'under attack'. " +
                                "Placeholders: Title, explanation, suggestion."),
                        status.title, status.explanation, status.suggestion)
                    finalText.append(NSAttributedString.boldAttributedString(from: messageString))
                }
                if let text = message.longMessage?.trimmed() {
                    finalText.append(NSAttributedString.normalAttributedString(from: text))
                } else if let text = message.longMessageFormatted?.attributedStringHtmlToMarkdown() {
                    finalText.append(NSAttributedString.normalAttributedString(from: text))
                } else if rating.isUnDecryptable() {
                    let cantDecryptMessage = NSLocalizedString("This message could not be decrypted.",
                                                               comment: "content that is shown for undecryptable messages")
                    finalText.append(NSAttributedString.normalAttributedString(from: cantDecryptMessage))
                } else {
                    // Empty body
                    finalText.append(NSAttributedString.normalAttributedString(from: ""))
                }
                DispatchQueue.main.async {
                    completion(finalText)
                }
            }
        }
    }

    // MARK: Attachment

    /// Do NOT instanciate this class directly, use a subclass instead.
    class BaseAttachmentRow: AttachmentRowProtocol {
        fileprivate var attachment: Attachment
        private let queue: OperationQueue = {
            var createe = OperationQueue()
            createe.qualityOfService = .userInitiated
            return createe
        }()

        public fileprivate(set) var cellIdentifier = ""
        public private(set) var filename = ""
        public private(set) var fileExtension: String?
        public private(set)  var icon: UIImage?
        public private(set) var isImage = false
        public fileprivate(set) var height: CGFloat = 0.0
        public var type: EmailViewModel.EmailRowType

        init(attachment: Attachment, type: EmailViewModel.EmailRowType) {
            self.attachment = attachment
            self.type = type
            retrieveAttachmentData()
        }

        /// Retrieve attachment data
        /// - Parameter completion: The callback to pass the data
        public func retrieveAttachmentData(completion: (() -> Void)? = nil) {
            if icon != nil {
                completion?()
            } else {
                loadAttachmentDataFromDisk() {
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
            }
        }

        /// Retrieve attachment from message
        ///
        /// - Parameters:
        ///   - completion: The completion block to execute when the attachment is obtained.
        private func loadAttachmentDataFromDisk(completion: @escaping () -> ()) {
            let attachmentViewOperation = AttachmentViewOperation(attachment: attachment) { [weak self] (container) in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }

                let defaultFileName = Attachment.defaultFilename
                switch container {
                case .imageAttachment(let attachment, let image):
                    me.filename = attachment.fileName ?? defaultFileName
                    me.fileExtension = attachment.mimeType
                    me.icon = image
                    me.isImage = true
                    completion()
                case .docAttachment(let attachment):
                    let (name, finalExt) = attachment.fileName?.splitFileExtension() ?? (defaultFileName, nil)
                    me.filename = name
                    me.fileExtension = finalExt

                    let dic = UIDocumentInteractionController()
                    dic.name = attachment.fileName
                    me.icon = dic.icons.first

                    me.isImage = false
                    completion()
                case .none:
                    Log.shared.errorAndCrash("This should never happen :-/")
                    completion()
                }
            }
            queue.addOperation(attachmentViewOperation)
        }
    }

    class AttachmentRow: BaseAttachmentRow {
        init(attachment: Attachment) {
            super.init(attachment: attachment, type: .attachment)
            cellIdentifier = "attachmentsCell"
            height = 120.0
        }
    }

    class ImageAttachmentRow: BaseAttachmentRow {
        init(attachment: Attachment) {
            super.init(attachment: attachment, type: .imageAttachment)
            cellIdentifier = "imageAttachmentCell"
        }
    }
}

//MARK:- Contact

extension EmailViewModel {

    /// Handle recipient button with username pressed
    /// - Parameter identity: The identity to populate the contact view.
    public func handleAddressButtonPressed(identity: Identity) {
        UIUtils.presentAddToContactsView(for: identity)
    }
}

//MARK:- Private

extension EmailViewModel {

    private func setupRows(message: Message) {
        func cellViewModels(from identities: [Identity], recipientType: EmailViewModel.RecipientType) -> [CollectionViewCellViewModel] {
            return identities.map({ return getRecipientCollectionViewCellViewModel(identity: $0, recipientType: recipientType) })
        }

        func getRecipientCollectionViewCellViewModel(identity: Identity, recipientType: EmailViewModel.RecipientType) -> CollectionViewCellViewModel {
            return CollectionViewCellViewModel(identity: identity, recipientType: recipientType) { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                me.handleAddressButtonPressed(identity: identity)
            }
        }

        /// The order of rows will be the order of cells in the screen.
        /// Sender
        guard let from = message.from else {
            Log.shared.errorAndCrash("From identity not found.")
            return
        }

        let fromVM = getRecipientCollectionViewCellViewModel(identity: from, recipientType: .from)
        let toRecipientsVMs = cellViewModels(from: message.uniqueTos, recipientType: .to)
        let ccRecipientsVMs = cellViewModels(from: message.uniqueCcs, recipientType: .cc)
        let bccRecipientsVMs = cellViewModels(from: message.uniqueBccs, recipientType: .bcc)
        let headerCellViewModel = MessageHeaderCellViewModel(displayedImageIdentity: from)
        let headerRow = HeaderRow(fromViewModel: fromVM,
                                  tosViewModels: toRecipientsVMs,
                                  ccsViewModels: ccRecipientsVMs,
                                  bccsViewModels: bccRecipientsVMs,
                                  date: message.sent?.fullString(),
                                  viewModel: headerCellViewModel)
        rows.append(headerRow)

        //Subject
        let title = message.shortMessage
        let subjectRow = SubjectRow(title: title ?? "")
        rows.append(subjectRow)

        //Body
        let bodyRow = BodyRow(htmlBody: htmlBody, message: message)
        rows.append(bodyRow)

        //Image Attachments
        let imageAttachmentRows: [ImageAttachmentRow] = message.viewableImageAttachments.map { ImageAttachmentRow(attachment: $0) }
        rows.append(contentsOf: imageAttachmentRows)

        //Non Inlined Attachments
        let attachmentRows = message.viewableNotInlinedAttachments.map { AttachmentRow(attachment: $0) }
        rows.append(contentsOf: attachmentRows)
    }
}
