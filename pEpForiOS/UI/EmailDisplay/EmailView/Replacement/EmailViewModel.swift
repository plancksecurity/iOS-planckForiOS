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
}

enum EmailRowType {
    //Sender includes 'from' and 'to'
    case sender, cc, bcc, subject, body, attachment
}

/// Protocol that represents the basic data in a row.
protocol EmailRowProtocol {
    /// The type of the row
    var type: EmailRowType { get }
    /// The first value of the row.
    var firstValue: String? { get }
    /// Returns the cell identifier
    var cellIdentifier: String { get }
    /// The second value of the row
    var secondValue: String? { get }
    /// The height of the row
    var height: CGFloat { get }
}

struct EmailViewModel {
    public struct AttachmentInformation2 {
        var filename: String
        var theExtension: String?
        var image: UIImage?
    }

    /// Delegate to comunicate with Email View.
    public weak var delegate: EmailViewModelDelegate?

    private var originalRows: [EmailRowProtocol]
    private var filteredRows: [EmailRowProtocol]
    private var message: Message

    // MARK: - Attachments

    private var attachments: [Attachment]
    private var viewContainers : [AttachmentViewContainer]?
    private let mimeTypes = MimeTypeUtils()
    private var buildOp: AttachmentsViewOperation?
    private let operationQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.qualityOfService = .userInitiated
        return createe
    }()

    /// Indicates if the message has attachments.
    public var hasAttachments: Bool {
        return !message.viewableAttachments().isEmpty
    }

    /// Constructor
    /// - Parameter message: The message to display
    public init(message: Message) {
        self.message = message

        self.attachments = message.viewableAttachments()
        var rowsTypes: [EmailRowType] = [.sender, .subject, .body]
        if attachments.count > 0 {
            rowsTypes.append(.attachment)
        }
        self.originalRows = rowsTypes.map { EmailRow(type: $0, message: message) }
        self.filteredRows = originalRows
    }

    // var showExternalContent = false
    /// Indicates if the show external content button should be shown.
    public var shouldShowExternalContent: Bool = false

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
        return filteredRows.count
    }

    /// Retrieves the row
    subscript(index: Int) -> EmailRowProtocol {
        get {
            return filteredRows[index]
        }
    }

    public func attachmentInformation(completion: @escaping ([AttachmentInformation2]?) -> Void) {
        self.updateQuickMetaData(message: message) { (attachmentInformations) in
            completion(attachmentInformations)
        }
    }

    /// Evaluates the pepRating to provide the body
    /// Use it for non-html content.
    /// - Parameter completion: The callback with the body.
    public func body(completion: @escaping (NSMutableAttributedString) -> Void) {
        let finalText = NSMutableAttributedString()
        message.pEpRating { (rating) in
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
        attachment.saveToTmpDirectory(defaultFilename: Attachment.defaultFilename) { (url) in
            guard let url = url else {
                Log.shared.errorAndCrash("No Local URL")
                return
            }
            delegate?.hideLoadingView()
            if shouldShowClientCertificate(url: url) {
                let clientCertificate = ClientCertificateImportViewModel(certificateUrl: url)
                delegate?.showClientCertificateImport(viewModel: clientCertificate)
            } else if QLPreviewController.canPreview(url as QLPreviewItem) {
                delegate?.showQuickLookOfAttachment(qlItem: url as QLPreviewItem)
            } else {
                delegate?.showDocumentsEditor(url: url)                
            }
            // If the message have an attachment
            // Show activity indicator.
            // Save the attachment temporarily in the directory
            // Show it to the user
        }
    }

    public struct EmailRow: EmailRowProtocol {
        public private(set) var type: EmailRowType
        public private(set) var firstValue: String?
        public private(set) var secondValue: String?
        public private(set) var height: CGFloat = 0.0
        public private(set) var cellIdentifier: String

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
            case .cc:
                self.firstValue = NSLocalizedString("CC:", comment: "Email field title")
                self.cellIdentifier = recipientCellIdentifier
                self.height = 0.0
            case .bcc:
                self.firstValue = NSLocalizedString("BCC:", comment: "Email field title")
                self.cellIdentifier = recipientCellIdentifier
                self.height = 0.0
            case .subject:
                self.firstValue = message.shortMessage
                if let originationDate = message.sent {
                    self.secondValue = (originationDate as Date).fullString()
                }
                self.cellIdentifier = subjectCellIdentifier
                self.height = 0.0
            case .body:
                self.cellIdentifier = senderBodyCellIdentifier
                self.height = 0.0
            case .attachment:
                self.cellIdentifier = attachmentsCellIdentifier
                self.height = 0.0
            }
        }
    }
}

extension EmailViewModel {

    private func updateQuickMetaData(message: Message, completion: @escaping ([AttachmentInformation2]) -> ()) {
        operationQueue.cancelAllOperations()
        let theBuildOp = AttachmentsViewOperation(mimeTypes: mimeTypes, message: message)
        theBuildOp.completionBlock = {
            DispatchQueue.main.async {
                self.opFinished(theBuildOp: theBuildOp, completion: completion)
            }
        }
        operationQueue.addOperation(theBuildOp)
    }

    private func opFinished(theBuildOp: AttachmentsViewOperation, completion: @escaping ([AttachmentInformation2]) -> ()) {
        var information: [AttachmentInformation2] = [AttachmentInformation2]()
        theBuildOp.attachmentContainers.forEach { (container) in
            switch container {
            case .imageAttachment(let attachment, let image):
                let safeAttachment = attachment.safeForSession(Session.main)
                Session.main.performAndWait {
                    let fileName = safeAttachment.fileName ?? Attachment.defaultFilename
                    let attachmentInformation2 = AttachmentInformation2(filename: fileName,
                                                                        theExtension: safeAttachment.mimeType,
                                                                        image: image)
                    information.append(attachmentInformation2)
                }
            case .docAttachment(let attachment):
                let safeAttachment = attachment.safeForSession(.main)
                Session.main.performAndWait {
                    let (name, finalExt) = safeAttachment.fileName?.splitFileExtension() ?? (Attachment.defaultFilename, nil)
                    let attachmentInformation2 = AttachmentInformation2(filename: name, theExtension: finalExt, image: UIDocumentInteractionController().icons.first)
                    information.append(attachmentInformation2)
                }
            }
        }
        completion(information)
    }
}

