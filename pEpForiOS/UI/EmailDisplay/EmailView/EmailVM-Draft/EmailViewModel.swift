//
//  EmailViewModel.swift
//  pEp
//
//  Created by Martin Brude on 08/09/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

protocol EmailViewModelDelegate {

}

final class EmailViewModel {

    private var message : Message
    public var items: [FieldViewModel] = [FieldViewModel]()
    public weak var emailViewModelDelegate: EmailViewModelDelegate?

    /// Constructor
    /// - Parameter message: The message to setup.
    init(message : Message, emailViewModelDelegate: EmailViewModelDelegate) {
        self.message = message
        self.EmailViewModelDelegate = emailViewModelDelegate
    }

    subscript(index: Int) -> FieldViewModel {
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

    public func show(documentAt url: URL, givenMimeType: String?) {

        // if ...,
        // delegate?.showPdfPreview
        // else
        // delegate?.showClientCertificateImport
        // or delegate?.presentDocumentInteractionController
    }

    public var showExternalContent = false
    public var showViewExternalContent = true

    public func saveToTmpDirectory(attachment : Attachment, completion: @escaping (URL?) -> Void) {

    }
    public func getClientCertificateImportViewModel(forClientCertificateAt url : URL) -> ClientCertificateImportViewModel? {
        return ClientCertificateImportViewModel(certificateUrl: url)
    }
}

class FieldViewModel {
    public enum FieldViewModelType : String {
        case to, cc, bcc, from, subject, content, mailingList, none, attachment, wrapped
    }
    private enum FieldDisplayType: String {
        case always, conditional
    }

    public var type: FieldViewModelType = .to
    public var display: FieldDisplayType = .always
    public var title : String {
        return ""
    }

    public var identifier {
        switch type {
        case .to:
            return ""
        default:
            return ""
        }
    }
}


<key>value</key>
<string></string>

<key>visible</key>
<string>always</string>

<key>contactSuggestion</key>

/// Protocol that represents the basic data in a row.
protocol FieldRowProtocol {
    /// The type of the row
    var type : AccountSettingsViewModel.RowType { get }
    /// The title of the row.
    var title: String { get }
    /// Indicates if the row action is dangerous.
    var isDangerous: Bool { get }
    /// Returns the cell identifier based on the index path.
    var cellIdentifier: String { get }
}
