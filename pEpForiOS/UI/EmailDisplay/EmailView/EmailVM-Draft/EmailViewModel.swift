////
////  EmailViewModel.swift
////  pEp
////
////  Created by Martin Brude on 08/09/2020.
////  Copyright © 2020 p≡p Security S.A. All rights reserved.
////
//
//import Foundation
//import MessageModel
//import QuickLook
//
//protocol EmailViewModelDelegate: class {
//    /// Show the preview of the Pdf in the provided URL
//    /// - Parameter url: The url of the PDF
//    func showPreview(ofPdfAt url : URL)
//    /// Show Certificates Import View.
//    func showClientCertificateImport()
//    /// Present the document the provided URL in a Document Controller
//    /// - Parameter url: The url of the document.
//    func presentDocumentInteractionController(ofPdfAt url : URL)
//}
//
//final class EmailViewModel {
//    private var message : Message
//    public var items: [EmailFieldRowProtocol] = [EmailFieldRowProtocol]()
//    public weak var emailViewModelDelegate: EmailViewModelDelegate?
//
//    public var shouldShowExternalContentButton = false
//    public var showViewExternalContent = true
//
//    /// Constructor
//    /// - Parameter message: The message to setup.
//    init(message : Message, emailViewModelDelegate: EmailViewModelDelegate) {
//        self.message = message
//        self.emailViewModelDelegate = emailViewModelDelegate
//        generateItems()
//    }
//
//    private func generateItems() {
//        let to = EmailFieldViewModel(type: .to)
//        let subject = EmailFieldViewModel(type: .subject)
//        let content = EmailFieldViewModel(type: .content)
//        let attachment = EmailFieldViewModel(type: .attachment)
//        items.append(contentsOf: [to, subject, content, attachment])
//    }
//
//    subscript(index: Int) -> EmailFieldRowProtocol {
//        get {
//            return self.items[index]
//        }
//    }
//
//    private func shouldShowCertificateImport(url: URL) -> Bool {
//        return url.pathExtension == "pEp12" || url.pathExtension == "pfx"
//    }
//
//    private func shouldShowPdf(url: URL, attachmentMimeType: String?) -> Bool {
//        guard let mimeType = attachmentMimeType else {
//            return false
//        }
//        return mimeType == MimeTypeUtils.MimesType.pdf && QLPreviewController.canPreview(url as QLPreviewItem)
//    }
//
//    /// Show the document at certain url
//    /// - Parameters:
//    ///   - url: The url of the document to show
//    ///   - attachmentMimeType: The given Mime Type.
//    public func show(documentAt url: URL, attachmentMimeType: String?) {
//        let bestMimeType = MimeTypeUtils.findBestMimeType(forFileAt: url, withGivenMimeType: attachmentMimeType)
//        if shouldShowCertificateImport(url: url) {
//            emailViewModelDelegate?.showClientCertificateImport()
//        } else if shouldShowPdf(url: url, attachmentMimeType: bestMimeType) {
//            emailViewModelDelegate?.showPreview(ofPdfAt: url)
//        } else {
////            documentInteractionController.url = url
////            let presentingView = view ?? cell
////            let dim: CGFloat = 40
////            let rect = CGRect.rectAround(center: location, width: dim, height: dim)
////            documentInteractionController.presentOptionsMenu(from: rect,
////                                                             in: presentingView,
////                                                             animated: true)
//        }
//    }
//
//    public func handleDidTap(rowAtIndex index   : Int, completion: @escaping () -> Void) {
//        
//    }
//
//    public func getClientCertificateImportViewModel(forClientCertificateAt url : URL) -> ClientCertificateImportViewModel? {
//        return ClientCertificateImportViewModel(certificateUrl: url)
//    }
//}
//
//public enum FieldViewModelType : String {
//    case to, cc, bcc, from, subject, content, mailingList, none, attachment, wrapped
//}
//public enum FieldDisplayType: String {
//    case always, conditional
//}
//
////MARK: - HTML
//
//extension EmailViewModel  {
//
//    /// Returns the HTML message body if:
//    /// * we can show it in a secure way
//    /// * we have non-empty HTML content at all
//    /// otherwise, returns nil.
//    public var htmlBody: String? {
//        guard let htmlBody = message.longMessageFormatted, !htmlBody.isEmpty else {
//            return nil
//        }
//        return htmlBody
//    }
//
//    /// Returns the HTML ready to display.
//    public func htmlToDisplay() -> String? {
//        guard let htmlBody = htmlBody else {
//            return nil
//        }
//
//        return appendInlinedPlainText(fromAttachmentsIn: message, to: htmlBody)
//    }
//
//    private func appendInlinedPlainText(fromAttachmentsIn message: Message, to text: String) -> String {
//        var result = text
//        let inlinedText = message.inlinedTextAttachments()
//        for inlinedTextAttachment in inlinedText {
//            guard let data = inlinedTextAttachment.data,
//                let inlinedText = String(data: data, encoding: .utf8) else {
//                    continue
//            }
//            result = append(appendText: inlinedText, to: result)
//        }
//        return result
//    }
//
//    private func append(appendText: String, to body: String) -> String {
//        var result = body
//        let replacee = result.contains(find: "</body>") ? "</body>" : "</html>"
//        if result.contains(find: replacee) {
//            result = result.replacingOccurrences(of: replacee, with: appendText + replacee)
//        } else {
//            result += "\n" + appendText
//        }
//        return result
//    }
//}
