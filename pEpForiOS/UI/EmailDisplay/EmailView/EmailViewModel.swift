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
}

//MARK: - EmailRowProtocol

protocol EmailRowProtocol {
    /// The cell identifier
    var cellIdentifier: String { get }
    var type: EmailViewModel.EmailRowType { get }
}

//MARK: - AttachmentRowProtocol

protocol AttachmentRowProtocol: EmailRowProtocol {
    var height: CGFloat { get set }
    func retrieveAttachmentData(completion: @escaping (String, String, UIImage) -> Void)
}

class EmailViewModel {

    /// Delegate to comunicate with Email View.
    public weak var delegate: EmailViewModelDelegate?
    private var rows: [EmailRowProtocol]
    private var message: Message
    private var attachments = [MessageModel.Attachment]()
    private var inlinedAttachments = [MessageModel.Attachment]()

    /// Constructor
    /// - Parameter message: The message to display
    public init(message: Message, delegate: EmailViewModelDelegate) {
        self.message = message
        self.delegate = delegate
        self.rows = [EmailRowProtocol]()
        self.attachments = message.viewableNotInlinedAttachments
        self.inlinedAttachments = message.viewableInlinedAttachments
        self.setupRows(message: message)
    }

    public func restart() {
        self.rows = [EmailRowProtocol]()
        self.attachments = message.viewableNotInlinedAttachments
        self.inlinedAttachments = message.viewableInlinedAttachments
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

        let defaultFileName = MessageModel.Attachment.defaultFilename
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
        if let row = rows[indexPath.row] as? BaseAttachmentRow {
            show(attachment: row.attachment)
        }
    }

    /// Handle the image has been loaded.
    /// - Parameters:
    ///   - indexPath: The indexPath of the cell that contains the image.
    ///   - height: The height of the image.
    public func handleImageFetched(forRowAt indexPath: IndexPath, withHeight height: CGFloat) {
        if let row = rows[indexPath.row] as? InlinedAttachmentRow {
            let margin: CGFloat = 20.0
            row.height = height + margin
            rows[indexPath.row] = row
        }
    }
}

//MARK: - Email Rows

extension EmailViewModel {
    enum EmailRowType: String {
        case sender, subject, body, attachment, inlinedAttachment
    }

    // MARK: Sender

    struct SenderRow: EmailRowProtocol {
        var type: EmailViewModel.EmailRowType = .sender
        var cellIdentifier: String = "senderCell"
        var from: String
        var to: String
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
                    finalText.normal(cantDecryptMessage)
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
                    finalText.bold(messageString)
                }
                if let text = message.longMessage?.trimmed() {
                    finalText.normal(text)
                } else if let text = message.longMessageFormatted?.attributedStringHtmlToMarkdown() {
                    finalText.normal(text)
                } else if rating.isUnDecryptable() {
                    let cantDecryptMessage = NSLocalizedString("This message could not be decrypted.",
                                                               comment: "content that is shown for undecryptable messages")
                    finalText.normal(cantDecryptMessage)
                } else {
                    // Empty body
                    finalText.normal("")
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
        public var height: CGFloat = 0.0
        public private(set) var cellIdentifier: String = ""
        public private(set) var type: EmailViewModel.EmailRowType
        public private(set) var attachment: MessageModel.Attachment
        public private(set) var operationQueue: OperationQueue
        private var message: Message?

        init(attachment: MessageModel.Attachment, type: EmailViewModel.EmailRowType) {
            self.operationQueue = OperationQueue()
            self.operationQueue.qualityOfService = .userInitiated
            self.attachment = attachment
            self.type = type
            guard let message = attachment.message else {
                Log.shared.errorAndCrash("Attachment with no Message")
                return
            }
            self.message = message

            if type == .attachment {
                cellIdentifier = "attachmentsCell"
                height = 120.0
            } else if type == .inlinedAttachment {
                cellIdentifier = "inlinedAttachmentCell"
            }
        }

        /// Retrieve attachment data
        /// - Parameter completion: The callback to pass the data.
        public func retrieveAttachmentData(completion: @escaping (String, String, UIImage) -> Void) {
            guard let message = message else {
                Log.shared.errorAndCrash("Attachment with no Message")
                return
            }
            retrieveAttachmentFromMessage(message: message) { (attachment) in
                DispatchQueue.main.async {
                    completion(attachment.filename, attachment.´extension´ ?? "", attachment.icon ?? UIImage())
                }
            }
        }

        /// Retrieve attachment from message
        ///
        /// - Parameters:
        ///   - message: The message to get the attachment
        ///   - completion: The completion block to execute when the attachment is obtained.
        private func retrieveAttachmentFromMessage(message: Message, completion: @escaping (AttachmentRow.Attachment) -> ()) {
            let attachmentViewOperation = AttachmentViewOperation(attachment: attachment) { (container) in
                let defaultFileName = MessageModel.Attachment.defaultFilename
                switch container {
                case .imageAttachment(let attachment, let image):
                    let safeAttachment = attachment.safeForSession(Session.main)
                    Session.main.performAndWait {
                        let fileName = safeAttachment.fileName ?? defaultFileName
                        let attachmentToReturn = AttachmentRow.Attachment(filename: fileName, ´extension´: safeAttachment.mimeType, icon: image, isImage: true)
                        completion(attachmentToReturn)
                    }
                case .docAttachment(let attachment):
                    let safeAttachment = attachment.safeForSession(.main)
                    Session.main.performAndWait {
                        let (name, finalExt) = safeAttachment.fileName?.splitFileExtension() ?? (defaultFileName, nil)
                        let dic = UIDocumentInteractionController()
                        dic.name = safeAttachment.fileName
                        let attachmentToReturn = AttachmentRow.Attachment(filename: name, ´extension´: finalExt, icon: dic.icons.first, isImage: false)
                        completion(attachmentToReturn)
                    }
                }
            }
            operationQueue.addOperation(attachmentViewOperation)
        }
    }

    class AttachmentRow: BaseAttachmentRow {
        /// Attachment, in the context of EmailViewModel.
        /// Do not confuse with MMO's Attachment.
        public struct Attachment {
            var filename: String = ""
            var ´extension´: String? // extension is a keyword, we need quotation marks
            var icon: UIImage?
            var isImage: Bool = false
        }

        init(attachment: MessageModel.Attachment) {
            super.init(attachment: attachment, type: .attachment)
        }
    }

    class InlinedAttachmentRow: BaseAttachmentRow {
        init(attachment: MessageModel.Attachment) {
            super.init(attachment: attachment, type: .inlinedAttachment)
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
        var tempTo: [String] = []
        message.allRecipients.forEach { (recepient) in
            let recepient = recepient.address
            tempTo.append(recepient)
        }
        let toDestinataries = NSLocalizedString("To:", comment: "Email field title") + tempTo.joined(separator: ", ")
        let senderRow = SenderRow(from: from, to: toDestinataries)
        rows.append(senderRow)

        //Subject
        let title = message.shortMessage
        let subjectRow = SubjectRow(title: title ?? "", date: message.sent?.fullString())
        rows.append(subjectRow)

        //Body
        let bodyRow = BodyRow(htmlBody: htmlBody, message: message)
        rows.append(bodyRow)

        //Inline Attachments
        let inlineAttachmentRows: [InlinedAttachmentRow] = inlinedAttachments.map { InlinedAttachmentRow(attachment: $0) }
        rows.append(contentsOf: inlineAttachmentRows)

        //Non Inlined Attachments
        let attachmentRows = attachments.map { AttachmentRow(attachment: $0) }
        rows.append(contentsOf: attachmentRows)
    }
}
