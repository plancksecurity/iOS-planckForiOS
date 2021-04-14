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
import Contacts

/// Delegate to comunicate with Email View.
protocol EmailViewModelDelegate: class {
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
    /// Show 'Add new contact' view
    /// - Parameter contact: The contact to add
    func showAddNewContact(contact: CNContact)
    /// Show 'Edit contact' view
    /// - Parameter contact: The contact to edit
    func showEditContact(contact: CNContact)
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
    public init(message: Message, delegate: EmailViewModelDelegate) {
        self.message = message
        self.delegate = delegate
        self.rows = [EmailRowProtocol]()
        self.setupRows(message: message)
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
    enum EmailRowType: String {
        case sender, subject, body, attachment, imageAttachment
    }

    // MARK: Sender

    struct SenderRow: EmailRowProtocol {
        var type: EmailViewModel.EmailRowType = .sender
        var cellIdentifier: String = "senderCell"
        var from: String
        var recipients: [String]
    }

    // MARK: Subject

    struct SubjectRow: EmailRowProtocol {
        var type: EmailViewModel.EmailRowType = .subject
        var cellIdentifier: String = "senderSubjectCell"
        var title: String
        var date: String?
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

//MARK:- Private

extension EmailViewModel {

    private func setupRows(message: Message) {
        /// The order of rows will be the order of cells in the screen.
        /// Sender
        guard let from = message.from?.displayString else {
            Log.shared.errorAndCrash("From identity not found.")
            return
        }
        let senderRow = SenderRow(from: from, recipients: message.allRecipients.map({$0.address}))
        rows.append(senderRow)

        //Subject
        let title = message.shortMessage
        let subjectRow = SubjectRow(title: title ?? "", date: message.sent?.fullString())
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

extension EmailViewModel {

    private func contactValue(address: String) -> CNContact? {
        let identity = Identity(address: address)
        let contact = CNMutableContact()
        if let userName = identity.userName {
            contact.givenName = userName
        }
        contact.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: address as NSString)]
        guard let cncontact = contact.copy() as? CNContact else {
            Log.shared.errorAndCrash("Can't cast contact")
            return nil
        }
        return cncontact
    }

    public func handleAddressButtonPressed(address: String) {
        guard let contact = contactValue(address: address) else {
            Log.shared.errorAndCrash("Contact is nil")
            return
        }
        guard let delegate = delegate else {
            Log.shared.errorAndCrash("Delegate is nil")
            return
        }
        let contacts = AddressBook.searchContacts(searchterm: address)
        if let contactToEdit = contacts.first {
            delegate.showEditContact(contact: contactToEdit)
        } else {
            delegate.showAddNewContact(contact: contact)
        }
    }
}
