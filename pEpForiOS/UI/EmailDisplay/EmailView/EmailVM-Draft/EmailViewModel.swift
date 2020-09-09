//
//  EmailViewModel.swift
//  pEp
//
//  Created by Martin Brude on 08/09/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol EmailViewModelDelegate: class {
    /// Show the preview of the Pdf in the provided URL
    /// - Parameter url: The url of the PDF
    func showPreview(ofPdfAt url : URL)
    /// Show Certificates Import View.
    func showClientCertificateImport()
    /// Present the PDF af the provided URL in a Document Controller
    /// - Parameter url: The url of the PDF
    func presentDocumentInteractionController(ofPdfAt url : URL)
}

final class EmailViewModel {
    private var message : Message
    public var items: [FieldRowProtocol] = [FieldRowProtocol]()
    public weak var emailViewModelDelegate: EmailViewModelDelegate?

    /// Constructor
    /// - Parameter message: The message to setup.
    init(message : Message, emailViewModelDelegate: EmailViewModelDelegate) {
        self.message = message
        self.emailViewModelDelegate = emailViewModelDelegate
    }

    subscript(index: Int) -> FieldRowProtocol {
        get {
            return self.items[index]
        }
    }

    /// Returns the HTML message body if:
    /// * we can show it in a secure way
    /// * we have non-empty HTML content at all
    /// otherwise, returns nil.
    public var htmlBody: String? {
        return nil
    }

    /// Returns the HTML ready to display.
    public func htmlToDisplay() -> String? {
        return ""
    }

    /// Show the document at certain url
    /// - Parameters:
    ///   - url: The url of the document to show
    ///   - attachmentMimeType: The given Mime Type.
    public func show(documentAt url: URL, attachmentMimeType: String?) {
        // if ...,
        // delegate?.showPdfPreview
        // else
        // delegate?.showClientCertificateImport
        // or delegate?.presentDocumentInteractionController
    }

    public var showExternalContent: Bool = false
    public var showViewExternalContent: Bool = true

    public func saveToTmpDirectory(attachment : Attachment, completion: @escaping (URL?) -> Void) {

    }
    public func getClientCertificateImportViewModel(forClientCertificateAt url : URL) -> ClientCertificateImportViewModel? {
        return ClientCertificateImportViewModel(certificateUrl: url)
    }
}

public enum FieldViewModelType : String {
    case to, cc, bcc, from, subject, content, mailingList, none, attachment, wrapped
}
public enum FieldDisplayType: String {
    case always, conditional
}

class FieldViewModel {

    public var type: FieldViewModelType = .to
    public var display: FieldDisplayType = .always
    public var title : String {
        return ""
    }

    public var identifier: String {
        switch type {
        case .to:
            return ""
        default:
            return ""
        }
    }
}

/// Protocol that represents the basic data in a row.
protocol FieldRowProtocol {
    /// The type of the row
    var type : FieldViewModelType { get }
    /// The title of the row.
    var title: String { get }
    /// Indicates if the row action is dangerous.
    var isDangerous: Bool { get }
    /// Returns the cell identifier based on the index path.
    var cellIdentifier: String { get }
}
