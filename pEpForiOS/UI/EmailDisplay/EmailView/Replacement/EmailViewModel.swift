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
    func showDocumentsEditor()
    /// Show Certificates Import View.
    /// - Parameter viewModel: The view model to setup the view.
    func showClientCertificateImport(viewModel: ClientCertificateImportViewModel)
    /// Shows the loading
    func showLoadingView()
    /// Hides the loading
    func hideLoadingView()
}

enum EmailRowType {
    case from, to, cc, bcc, subject, body, attachment
}

/// Protocol that represents the basic data in a row.
protocol EmailRowProtocol {
    /// The type of the row
    var type: EmailRowType { get }
    /// The title of the row.
    var title: String? { get }
    /// Returns the cell identifier
    var cellIdentifier: String { get }
    /// The content of the row
    var content: String? { get }
}

struct EmailViewModel {
    /// Delegate to comunicate with Email View.
    public weak var delegate: EmailViewModelDelegate?
    private var originalRows: [EmailRowProtocol]
    private var filteredRows: [EmailRowProtocol]
    private var message: Message

    /// Constructor
    /// - Parameter message: The message to display
    init(message: Message) {
        self.message = message
        self.originalRows = EmailViewModel.generateRows(message: message)
        self.filteredRows = originalRows
    }

    public struct EmailRow: EmailRowProtocol {
        public private(set) var type: EmailRowType
        public private(set) var content: String?
        public private(set) var title: String?
        public private(set) var height: CGFloat = 0.0
        public private(set) var cellIdentifier: String

        /// Constructor
        /// - Parameter type: The type of the row
        init(type: EmailRowType) {
            let recipientCellIdentifier = "senderCell"
            let subjectCellIdentifier = "senderSubjectCell"
            let attachmentsCellIdentifier = "attachmentsCell"
            let senderBodyCellIdentifier = "senderBodyCell"
            self.type = type
            switch type {
            case .to:
                self.title = NSLocalizedString("To:", comment: "Email field title")
                self.cellIdentifier = recipientCellIdentifier
                self.height = 0.0
            case .from:
                self.title = NSLocalizedString("From:", comment: "Email field title")
                self.cellIdentifier = recipientCellIdentifier
                self.height = 0.0
            case .cc:
                self.title = NSLocalizedString("CC:", comment: "Email field title")
                self.cellIdentifier = recipientCellIdentifier
                self.height = 0.0
            case .bcc:
                self.title = NSLocalizedString("BCC:", comment: "Email field title")
                self.cellIdentifier = recipientCellIdentifier
                self.height = 0.0
            case .subject:
                self.title = NSLocalizedString("Subject:", comment: "Email field title")
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

    /// Indicates if the show external content button should be shown.
    public var shouldShowExternalContentButton: Bool = false

    /// Indicates if the html viewer should be shown.
    public var shouldShowHtmlViewer: Bool = false

    /// Yields the HTML message body if we can show it in a secure way or we have non-empty HTML content at all
    public var htmlBody: String? {
        return nil
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

    /// Evaluates the pepRating to provide the body
    /// Use it for non-html content.
    /// - Parameter completion: The callback with the body.
    public func body(completion: @escaping (NSMutableAttributedString) -> Void) {
        let finalText = NSMutableAttributedString()
        message.pEpRating { (rating) in
            DispatchQueue.main.async {
                completion(finalText)
            }
        }
    }

    /// Handle the user tap gesture over the mail attachment
    /// - Parameter index: The index of the attachment
    public func handleDidTapAttachment(at indexPath: IndexPath) {
        // If the message have an attachment
        // Show activity indicator.
        // Save the attachment temporarily in the directory
        // Show it to the user
    }
}

// MARK: - Private

extension EmailViewModel {

    private static func generateRows(message: Message) -> [EmailRowProtocol] {
        /// Fill al rows with its content, except for body.
        return [EmailRowProtocol]()
    }

    /// Decide on the rows that should be visible, based on the message.
    private func filterRows() -> [EmailRowProtocol] {
//        if let viewableAttachments = message?.viewableAttachments(),
//            viewableAttachments.count == 0 {
//            filterRows(filter: { $0.type != .mailingList && $0.type != .attachment} )
//        } else {
//            filterRows(filter: { $0.type != .mailingList} )
//        }
//        Log.shared.info("filtering rows")
        return [EmailRowProtocol]()
    }
}
