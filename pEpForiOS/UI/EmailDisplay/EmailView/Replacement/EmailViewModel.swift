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
}

enum EmailRowType {
    //Sender includes 'from' and 'to'
    case sender, subject, body, attachment
}

//MB:- split into different RowProtocols as Settings.

/// Protocol that represents the basic data in a row.
protocol EmailRowProtocol {
    /// The type of the row
    var type: EmailRowType { get }
    /// The first value of the row.
    var firstValue: String? { get set }
    /// Returns the cell identifier
    var cellIdentifier: String { get }
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

    private var attachments: [MessageModel.Attachment]
    private var viewContainers : [AttachmentViewContainer]?
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
        self.attachments = message.viewableAttachments()
        var rowsTypes: [EmailRowType] = [.sender, .subject, .body]
        self.attachments.forEach { (attachment) in
            rowsTypes.append(.attachment)
        }
        self.rows = rowsTypes.map { Row(type: $0, message: message) }
    }

    // var showExternalContent = false
    /// Indicates if the show external content button should be shown.
    public var shouldShowExternalContent: Bool = false

    //MB:- rm doc.
    // var showViewExternalContent = true
    /// Indicates if the html viewer should be shown.
    public var shouldShowHtmlViewer: Bool = true

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

    /// Retrieve the attachments.
    /// When done -or if they were already retrieved-, the delegate will inform it.
    public func retrieveAttachments() {
        func getIndexPathsOfAttachments(with data: [EmailViewModel.Attachment]? = nil) -> [IndexPath] {
            var indexPaths = [IndexPath]()
            var dataIndex = 0
            for i in 0..<rows.count {
                if rows[i].type == .attachment {
                    if let data = data {
                        rows[i].firstValue = data[dataIndex].filename
                        rows[i].secondValue = data[dataIndex].´extension´
                        rows[i].image = data[dataIndex].image
                        dataIndex += 1
                    }
                    let indexPath = IndexPath(row: i, section: 0)
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
            updateQuickMetaData(message: message) { [weak self] (data) in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                let indexPaths = getIndexPathsOfAttachments(with: data)
                me.didRetrieveAttachments = true
                me.delegate?.didSetAttachments(forRowsAt: indexPaths)
                me.isRetrievingAttachments = false
            }
        } else {
            let indexPaths = getIndexPathsOfAttachments()
            delegate?.didSetAttachments(forRowsAt: indexPaths)
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
        guard attachments.count > indexPath.row else {
            Log.shared.errorAndCrash("attachments Out of bounds")
            return
        }

        let attachment = attachments[indexPath.row]
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

// MARK: - Public structs to use EmailViewModel

extension EmailViewModel {

    /// Attachment, in the context of EmailViewModel.
    /// Do not confuse with MMO's Attachment.
    public struct Attachment {
        var filename: String = ""
        var ´extension´: String? // extension is a keyword, we need quotation marks
        var image: UIImage?
    }

    /// Attachment inherits from Row
    public struct Row: EmailRowProtocol {
        public private(set) var type: EmailRowType
        public private(set) var height: CGFloat = 0.0
        public private(set) var cellIdentifier: String
        public var firstValue: String?
        public var secondValue: String?
        public var image: UIImage?

        /// Constructor
        /// - Parameters:
        ///   - type: The type of the row
        ///   - message: The message to setup the row
        init(type: EmailRowType, message: Message) {
            let recipientCellIdentifier = "senderCell"
            let subjectCellIdentifier = "senderSubjectCell"
            let attachmentsCellIdentifier = "attachmentsCell"
            let senderBodyCellIdentifier = "senderBodyCell"
            self.type = type
            switch type {
            case .sender:
                self.cellIdentifier = recipientCellIdentifier
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
                self.cellIdentifier = subjectCellIdentifier
                // MB:- Set height or remove
                self.height = 0.0
            case .body:
                self.cellIdentifier = senderBodyCellIdentifier
                // MB:- Set height or remove
                self.height = 0.0
            case .attachment:
                self.cellIdentifier = attachmentsCellIdentifier
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
        var information: [EmailViewModel.Attachment] = [EmailViewModel.Attachment]()
        theBuildOp.attachmentContainers.forEach { (container) in
            switch container {
            case .imageAttachment(let attachment, let image):
                let safeAttachment = attachment.safeForSession(Session.main)
                Session.main.performAndWait {
                    let fileName = safeAttachment.fileName ?? defaultFileName
                    let attachmentRow = EmailViewModel.Attachment(filename: fileName, ´extension´: safeAttachment.mimeType, image: image)
                    information.append(attachmentRow)
                }
            case .docAttachment(let attachment):
                let safeAttachment = attachment.safeForSession(.main)
                Session.main.performAndWait {
                    let (name, finalExt) = safeAttachment.fileName?.splitFileExtension() ?? (defaultFileName, nil)
                    let dic = UIDocumentInteractionController()
                    dic.name = safeAttachment.fileName
                    let row = EmailViewModel.Attachment(filename: name, ´extension´: finalExt, image: dic.icons.first)
                    information.append(row)
                }
            }
        }
        completion(information)
    }
}
