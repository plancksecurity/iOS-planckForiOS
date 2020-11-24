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
    /// - Parameter qlItem: The quick look item to show. Could be the url of a document.
    func showQuickLookOfAttachment(qlItem: QLPreviewItem)
    /// Show Documents Editor
    /// - Parameter url: The url of the document
    func showDocumentsEditor(url: URL)
    /// Show Certificates Import View.
    /// - Parameter viewModel: The view model to setup the view.
    func showClientCertificateImport(viewModel: ClientCertificateImportViewModel)
    /// Shows the loading
    func showLoadingView()
    /// Hides the loading
    func hideLoadingView()
    /// Informs the attachments have been set.
    /// - Parameter indexPaths: The indexPath of the attachments
    func didSetAttachments(forRowsAt indexPaths: [IndexPath])
    /// Informs the viewModel is ready to provide external content.
    func showExternalContent()
}

enum EmailRowType: String {
    case sender, subject, body, attachment
}

/// Protocol that represents the basic data in a row.
protocol EmailRowProtocol {
    /// The type of the row
    var type: EmailRowType { get }
    /// The first value of the row.
    var firstValue: String? { get set }
    /// The second value of the row
    var secondValue: String? { get set }
    /// The height of the row
    var height: CGFloat { get }
    /// The image of the row
    var image: UIImage? { get set }
}

class EmailViewModel {

    /// Delegate to comunicate with Email View.
    public weak var delegate: EmailViewModelDelegate?

    private var rows: [EmailRowProtocol]
    private var message: Message

    // MARK: - Attachments
    public var didRetrieveAttachments: Bool = false
    public var isRetrievingAttachments: Bool = false

    private var retrievedAttachments: [Attachment]?

    private var attachments = [MessageModel.Attachment]()
    private var buildOp: AttachmentsViewOperation?
    private let operationQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInitiated
        return createe
    }()

    /// Constructor
    /// - Parameter message: The message to display
    public init(message: Message, delegate: EmailViewModelDelegate) {
        self.message = message
        self.delegate = delegate
        self.attachments = message.viewableAttachments().filter({!$0.isInlined})
        var rowsTypes: [EmailRowType] = [.sender, .subject, .body]
        self.attachments.forEach { (attachment) in
            rowsTypes.append(.attachment)
        }
        self.rows = rowsTypes.map { Row(type: $0, message: message) }
    }

    private var shouldHideExternalContent: Bool = true

    // Indicates if the External Content View has to be shown.
    public var shouldShowExternalContentView: Bool {
        guard let body = htmlBody else {
            return false
        }
        return body.containsExternalContent() && shouldHideExternalContent
    }

    /// Yields the HTML message body if we can show it in a secure way or we have non-empty HTML content at all
    public var htmlBody: String? {
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
        let row = rows[indexPath.row]
        switch row.type {
        case .sender:
            return "senderCell"
        case .subject:
            return "senderSubjectCell"
        case .body:
            return "senderBodyCell"
        case .attachment:
            return "attachmentsCell"
        }
    }

    func handleDidTapShowExternalContentButton() {
        shouldHideExternalContent = false
        delegate?.showExternalContent()
    }

    /// Retrieve the attachments.
    /// When done -or if they were already retrieved-, the delegate will inform it.
    public func retrieveAttachments() {

        /// Retrieves the IndexPaths of the rows with attachments.
        /// - Parameter attachments: The attachments
        /// - Returns: The indexPaths of the attachments
        func getIndexPathsOfRows(with attachments: [EmailViewModel.Attachment]) -> [IndexPath] {
            var indexPaths = [IndexPath]()
            var dataIndex = 0
            for index in 0..<rows.count {
                if rows[index].type == .attachment {
                    guard !attachments[dataIndex].isImage else {
                        continue
                    }
                    rows[index].firstValue = attachments[dataIndex].filename
                    rows[index].secondValue = attachments[dataIndex].´extension´
                    rows[index].image = attachments[dataIndex].icon
                    dataIndex += 1
                    let indexPath = IndexPath(row: index, section: 0)
                    indexPaths.append(indexPath)
                }
            }
            return indexPaths
        }

        if isRetrievingAttachments {
            Log.shared.info("Already getting attachments. Nothing to do.")
            return
        }
        if !didRetrieveAttachments {
            isRetrievingAttachments = true
            updateQuickMetaData(message: message) { [weak self] (retrievedAttachments) in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                guard retrievedAttachments.count > 0 else {
                    // Valid case: there is no attachments
                    return
                }

                me.retrievedAttachments = retrievedAttachments
                let indexPaths = getIndexPathsOfRows(with: retrievedAttachments)
                me.didRetrieveAttachments = true
                DispatchQueue.main.async {
                    me.delegate?.didSetAttachments(forRowsAt: indexPaths)
                }
                me.isRetrievingAttachments = false
            }
        } else if let retrievedAttachments = retrievedAttachments {
            let indexPaths = getIndexPathsOfRows(with: retrievedAttachments)
            DispatchQueue.main.async {
                self.delegate?.didSetAttachments(forRowsAt: indexPaths)
            }
        }
    }

    /// Evaluates the pepRating to provide the body
    /// Use it for non-html content.
    /// - Parameter completion: The callback with the body.
    public func body(completion: @escaping (NSMutableAttributedString) -> Void) {
        let finalText = NSMutableAttributedString()
        message.pEpRating { [weak self] (rating) in
            guard let message = self?.message else {
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

    /// Handle the user tap gesture over the mail attachment
    /// - Parameter index: The index of the attachment
    public func handleDidTapAttachment(at indexPath: IndexPath) {
        func shouldShowClientCertificate(url : URL) -> Bool {
            return url.pathExtension == "pEp12" || url.pathExtension == "pfx"
        }

        delegate?.showLoadingView()
        guard rows.count > indexPath.row else {
            Log.shared.errorAndCrash("attachments Out of bounds")
            return
        }

        let index = indexPath.row - rows.count(where: {$0.type != .attachment})
        let attachment = attachments[index]
        let defaultFileName = MessageModel.Attachment.defaultFilename
        attachment.saveToTmpDirectory(defaultFilename: defaultFileName) { [weak self] (url) in
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
                    me.delegate?.showQuickLookOfAttachment(qlItem: url as QLPreviewItem)
                } else {
                    me.delegate?.showDocumentsEditor(url: url)
                }
            }
        }
    }
}

// MARK: - Public structs to use EmailViewModel

extension EmailViewModel {

    /// Attachment, in the context of EmailViewModel.
    /// Do not confuse with MMO's Attachment.
    public struct Attachment {
        var filename: String = ""
        var ´extension´: String? // extension is a keyword, we need quotation marks
        var icon: UIImage?
        var isImage: Bool = false
    }

    /// Attachment inherits from Row
    public struct Row: EmailRowProtocol {
        public private(set) var type: EmailRowType
        public private(set) var height: CGFloat = 0.0
        public var firstValue: String?
        public var secondValue: String?
        public var image: UIImage?

        /// Constructor
        /// - Parameters:
        ///   - type: The type of the row
        ///   - message: The message to setup the row
        init(type: EmailRowType, message: Message) {
            self.type = type
            switch type {
            case .sender:
                self.firstValue = message.from?.displayString
                var temp: [String] = []
                message.allRecipients.forEach { (recepient) in
                    let recepient = recepient.address
                    temp.append(recepient)
                }
                let toDestinataries = NSLocalizedString("To:", comment: "Compose field title") + temp.joined(separator: ", ")
                self.secondValue = toDestinataries
                self.height = 64.0
            case .subject:
                self.firstValue = message.shortMessage
                if let originationDate = message.sent {
                    self.secondValue = (originationDate as Date).fullString()
                }
            case .body:
                Log.shared.info("Nothing to do here.")
            case .attachment:
                self.height = 120.0
            }
        }
    }
}

// MARK: - Private

extension EmailViewModel {

    private func updateQuickMetaData(message: Message, completion: @escaping ([EmailViewModel.Attachment]) -> ()) {
        let mimeTypes = MimeTypeUtils()
        operationQueue.cancelAllOperations()
        let theBuildOp = AttachmentsViewOperation(mimeTypes: mimeTypes, message: message)
        theBuildOp.completionBlock = {
            DispatchQueue.main.async {
                self.opFinished(theBuildOp: theBuildOp, completion: completion)
            }
        }
        operationQueue.addOperation(theBuildOp)
    }

    private func opFinished(theBuildOp: AttachmentsViewOperation, completion: @escaping ([EmailViewModel.Attachment]) -> ()) {
        let defaultFileName = MessageModel.Attachment.defaultFilename
        var attachmentRows: [EmailViewModel.Attachment] = [EmailViewModel.Attachment]()
        theBuildOp.attachmentContainers.forEach { (container) in
            switch container {
            case .imageAttachment(let attachment, let image):
                let safeAttachment = attachment.safeForSession(Session.main)
                Session.main.performAndWait {
                    let fileName = safeAttachment.fileName ?? defaultFileName
                    let attachmentRow = EmailViewModel.Attachment(filename: fileName, ´extension´: safeAttachment.mimeType, icon: image, isImage: true)
                    attachmentRows.append(attachmentRow)
                }
            case .docAttachment(let attachment):
                let safeAttachment = attachment.safeForSession(.main)
                Session.main.performAndWait {
                    let (name, finalExt) = safeAttachment.fileName?.splitFileExtension() ?? (defaultFileName, nil)
                    let dic = UIDocumentInteractionController()
                    dic.name = safeAttachment.fileName
                    let row = EmailViewModel.Attachment(filename: name, ´extension´: finalExt, icon: dic.icons.first, isImage: false)
                    attachmentRows.append(row)
                }
            }
        }
        completion(attachmentRows)
    }
}
