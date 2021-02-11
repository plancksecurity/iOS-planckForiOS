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

enum EmailRowType: String {
   case sender, subject, body, attachment
}

protocol EmailRowProtocol {
    /// The cell identifier
    var cellIdentifier: String { get }
}

//MARK: - Sender

protocol SenderRowProtocol: EmailRowProtocol {
    /// From recipient text
    var from: String { get }
    /// To recipient text
    var to: String { get }
}

struct SenderRow: SenderRowProtocol {
    var cellIdentifier: String = "senderCell"
    var from: String
    var to: String
}

//MARK: - Subject

protocol SubjectRowProtocol: EmailRowProtocol {
    var title: String { get }
    var date: String? { get }
}

struct SubjectRow: SubjectRowProtocol {
    var cellIdentifier: String = "senderSubjectCell"
    var title: String
    var date: String?
}

//MARK: - Body

protocol BodyRowProtocol: EmailRowProtocol {
    /// The html body of the message
    var htmlBody: String? { get }
    /// Evaluates the pepRating to provide the body
    /// Use it for non-html content.
    /// - Parameter completion: The callback with the body.
    func body(completion: @escaping (NSMutableAttributedString) -> Void)
}

struct BodyRow: BodyRowProtocol {
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

//MARK: - AttachmentRowProtocol

protocol AttachmentRowProtocol: EmailRowProtocol {
    var height: CGFloat { get }
    func retrieveAttachmentData(completion: @escaping (String, String, UIImage) -> Void)
}

struct AttachmentRow: AttachmentRowProtocol {
    var cellIdentifier: String = "attachmentsCell"

    /// Attachment, in the context of EmailViewModel.
    /// Do not confuse with MMO's Attachment.
    public struct Attachment {
        var filename: String = ""
        var ´extension´: String? // extension is a keyword, we need quotation marks
        var icon: UIImage?
        var isImage: Bool = false
    }

    private(set) public var attachmentIndex: Int
    private var operationQueue: OperationQueue
    private var message: Message
    public var height: CGFloat

    init(message: Message, attachmentIndex: Int) {
        self.operationQueue = OperationQueue()
        self.operationQueue.qualityOfService = .userInitiated
        self.message = message
        self.height = 120.0
        self.attachmentIndex = attachmentIndex
    }

    /// Retrieve attachment data
    /// - Parameter completion: The callback to pass the data.
    public func retrieveAttachmentData(completion: @escaping (String, String, UIImage) -> Void) {
        retrieveAttachmentFromMessage(withIndex: attachmentIndex, message: message) { (attachment) in
            DispatchQueue.main.async {
                completion(attachment.filename, attachment.´extension´ ?? "", attachment.icon ?? UIImage())
            }
        }
    }

    private func retrieveAttachmentFromMessage(withIndex index: Int,
                                               message: Message,
                                               completion: @escaping (AttachmentRow.Attachment) -> ()) {
        func prepareAttachmentRow(attachmentViewOperation: AttachmentViewOperation,
                                  completion: @escaping (AttachmentRow.Attachment) -> ()) {
            let defaultFileName = MessageModel.Attachment.defaultFilename

            guard let container = attachmentViewOperation.container else {
                /// Valid case, could be an inline attachment
                return
            }
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
        operationQueue.cancelAllOperations()
        let attachmentViewOperation = AttachmentViewOperation(message: message, attachmentIndex: index)
        attachmentViewOperation.completionBlock = {
            DispatchQueue.main.async {
                prepareAttachmentRow(attachmentViewOperation: attachmentViewOperation, completion: completion)
            }
        }
        operationQueue.addOperation(attachmentViewOperation)
    }
}

class EmailViewModel {

    /// Delegate to comunicate with Email View.
    public weak var delegate: EmailViewModelDelegate?
    private var rows: [EmailRowProtocol]
    private var message: Message
    private var attachments = [MessageModel.Attachment]()

    /// Constructor
    /// - Parameter message: The message to display
    public init(message: Message, delegate: EmailViewModelDelegate) {
        self.message = message
        self.delegate = delegate
        self.rows = [EmailRowProtocol]()

        self.attachments = message.viewableAttachments().filter({
            !$0.isInlined
        })
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

    /// Get the row type of the row.
    /// - Parameter row: The row
    /// - Returns: The Email Row type
    public func type(ofRow row: EmailRowProtocol) -> EmailRowType {
        if row is SenderRowProtocol {
            return .sender
        } else if row is BodyRowProtocol {
            return .body
        } else if row is SubjectRowProtocol {
            return .subject
        } else if row is AttachmentRowProtocol {
            return .attachment
        }
        Log.shared.errorAndCrash("Row type not supported")
        return .sender
    }

    /// Show external content.
    public func handleShowExternalContentButtonPressed() {
        shouldHideExternalContent = false
        delegate?.showExternalContent()
    }

    /// Handle the user tap gesture over the mail attachment
    /// - Parameter index: The index of the attachment
    public func handleDidTapAttachmentRow(at indexPath: IndexPath) {
        func shouldShowClientCertificate(url : URL) -> Bool {
            return url.pathExtension == "pEp12" || url.pathExtension == "pfx"
        }
        delegate?.showLoadingView()
        guard rows.count > indexPath.row else {
            Log.shared.errorAndCrash("attachments Out of bounds")
            return
        }
        let index = indexPath.row - rows.count(where: {
            type(ofRow: $0) != .attachment
        })
        let attachment = attachments[index]
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
}

//MARK:- Private

extension EmailViewModel {

    private func setupRows(message: Message) {
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

        //Attachments
        for attachmentIndex in 0..<attachments.count {
            let attachmentRow = AttachmentRow(message: message, attachmentIndex: attachmentIndex)
            rows.append(attachmentRow)
        }
    }

}
