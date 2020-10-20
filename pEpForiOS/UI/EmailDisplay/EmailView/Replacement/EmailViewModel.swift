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
    case to, cc, bcc, from, subject, content, mailingList, none, attachment, wraped
}

/// Protocol that represents the basic data in a row.
protocol EmailRowProtocol {
    /// The type of the row
    var type: EmailRowType { get }
    /// The title of the row.
    var title: String { get }
    /// Returns the cell identifier
    var cellIdentifier: String { get }
}

struct EmailViewModel {
    /// Delegate to comunicate with Email View.
    public weak var delegate: EmailViewModelDelegate?
    private var rows : [EmailRowProtocol]
    private var message: Message
    
    init(message: Message) {
        self.message = message
        self.rows = EmailViewModel.generateRows(message: message)
    }
    
    private static func generateRows(message: Message) -> [EmailRowProtocol] {
        return [EmailRowProtocol]()
    }

    public struct EmailRow: EmailRowProtocol {
        var type: EmailRowType
        var title: String
        var cellIdentifier: String
    }

    /// Indicates if the show external content button should be shown.
    public var shouldShowExternalContentButton: Bool = false

    /// Indicates if the html viewer should be shown.
    public var shouldShowHtmlViewer: Bool = false

    /// Yields the HTML message body if we can show it in a secure way or we have non-empty HTML content at all
    public var htmlBody: String? {
        return nil
    }

    /// The plaintext body, only in case the HTML body does not exist. Otherwise nil.
    public var plainTextBody: String? {
        return nil
    }
    
    /// Retrieves the row
    public subscript(index: Int) -> EmailRowProtocol {
        get {
            return rows[index]
        }
    }

    /// Handle event of tap on message.
    /// - Parameter indexPath: The indexPath of the message tapped.
    public func handleDidTapMessage() {
        // Show spinner.

        /// get attachment.
        
//        delegate?.show(item: item)
    }
}
