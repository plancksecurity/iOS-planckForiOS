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

/// Delegate to comunicate with Email View.
protocol EmailViewModelDelegate: class {
    /// Show the item
    /// - Parameter item: The item to show
    func show(item: QLPreviewItem)
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

enum EmailRowType: String {
    case to, cc, bcc, from, subject, body, mailingList, none, attachment, wraped
}

enum EmailRowVisibility: String {
    case always, conditional
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
    var content: String { get }
    /// Indicates if the row is always visible.
    var visibility: EmailRowVisibility { get }
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
        var type: EmailRowType
        var visibility: EmailRowVisibility
        var content: String
        var title: String?
        var cellIdentifier: String

        /// Constructor
        /// - Parameter type: The type of the row
        init(type: EmailRowType) {
            let recipientCellIdentifier = "senderCell"
            let wrappedCellIdentifier = "wrappedCell"
            let accountCellIdentifier = "accountCell"
            let subjectCellIdentifier = "senderSubjectCell"
            let attachmentsCellIdentifier = "attachmentsCell"
            let senderBodyCellIdentifier = "senderBodyCell"
            self.type = type
            switch type {
            case .to:
                self.title = NSLocalizedString("To:", comment: "Email field title")
                self.cellIdentifier = recipientCellIdentifier
                self.visibility = .always
            case .cc:
                self.title = NSLocalizedString("CC:", comment: "Email field title")
                self.cellIdentifier = recipientCellIdentifier
                self.visibility = .conditional
            case .bcc:
                self.title = NSLocalizedString("BCC:", comment: "Email field title")
                self.cellIdentifier = recipientCellIdentifier
                self.visibility = .conditional
            case .wraped:
                self.title = NSLocalizedString("Cc/Bcc:", comment: "Email field title")
                self.cellIdentifier = wrappedCellIdentifier
                self.visibility = .conditional
            case .from:
                self.title = NSLocalizedString("From:", comment: "Email field title")
                self.cellIdentifier = accountCellIdentifier
                self.visibility = .conditional
            case .subject:
                self.title = NSLocalizedString("Subject:", comment: "Email field title")
                self.cellIdentifier = subjectCellIdentifier
                self.visibility = .always

            case .mailingList:
                self.title = NSLocalizedString("This message is from a mailing list.", comment: "Compose field title")
                self.cellIdentifier = ""
            case .body:
                self.cellIdentifier = senderBodyCellIdentifier
            case .none:
                self.cellIdentifier = ""
            case .attachment:
                self.cellIdentifier = ""
            }
            self.content = ""
            self.visibility = .always
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

    /// Retrieves the row
    subscript(index: Int) -> EmailRowProtocol {
        get {
            return filteredRows[index]
        }
    }

    /// Number of rows
    public var numberOfRows: Int {
        return filteredRows.count
    }

    /// Handle the user tap gesture over the mail
    /// If has an attachment, will be shown.
    public func handleDidTapMessage() {
        // If the message have an attachment
        // Show activity indicator.
        // Save the attachment temporarily in the directory
        // Show it to the user
    }

    /// Evaluates the pepRating to provide the body
    /// - Parameter completion: The callback with the body.
    public func body(completion: @escaping (NSMutableAttributedString) -> Void) {
        let finalText = NSMutableAttributedString()
        message.pEpRating { (rating) in
            completion(finalText)
        }
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
