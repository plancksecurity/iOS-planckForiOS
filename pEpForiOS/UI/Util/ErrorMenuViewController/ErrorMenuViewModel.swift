//
//  ErrorMenuViewModel.swift
//  pEp
//
//  Created by Martín Brude on 9/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

///Delegate protocol to communicate to the ViewController.
protocol ErrorMenuViewModelDelegate: AnyObject {
    /// Close the Notification
    func closeNotification()

    /// Show alert view
    func showAlerView()
}

/// Protocol that represents the basic data in a row.
protocol ErrorMenuRowProtocol {
    // Identifier of the row
    var identifier : ErrorMenuViewModel.RowIdentifier { get }
    /// Title of the row.
    var title: String { get }
}

class ErrorMenuViewModel {

    public let cellIdentifier = "errorMenuActionCell"

    /// Struct that is used to perform an action.
    /// Represents a ActionRow in the Error Menu View Controller
    public struct ActionRow: ErrorMenuRowProtocol {
        var identifier: ErrorMenuViewModel.RowIdentifier
        /// Title of the action row
        var title: String
        /// Block that will be executed when action cell is pressed
        var action: ActionBlock?
        /// The cell identifier
        var cellIdentifier: String
    }

    public private(set) var rows = [ErrorMenuRowProtocol]()
    public weak var delegate : ErrorMenuViewModelDelegate?
    typealias ActionBlock = (() -> Void)

    /// The error message to be copied
    public var errorMessageToCopy : String?

    /// Identifies semantically the type of row.
    public enum RowIdentifier: CaseIterable {
        case seeMessage
        case copyMessage
        case closeNotification
    }

    /// Number of rows
    public var count: Int {
        get {
            return rows.count
        }
    }

    /// Constructor
    public init(delegate: ErrorMenuViewModelDelegate) {
        self.delegate = delegate
        setup()
    }

    /// Handle the row selection
    ///
    /// - Parameter rowAt: The indexPath of the selected row
    public func handleDidSelect(rowAt: IndexPath) {
        guard let row = rows[rowAt.row] as? ActionRow else {
            Log.shared.errorAndCrash(error: "Row not found")
            return
        }
        row.action?()
    }
}

// MARK: - Private

extension ErrorMenuViewModel {

    private func setup() {
        rows = generateRows()
    }

    /// This method generates all the rows for the section type passed
    /// - Parameter type: The type of the section to generate the rows.
    /// - Returns: An array with the settings rows. Every setting row must conform the SettingsRowProtocol.
    private func generateRows() -> [ErrorMenuRowProtocol] {
        var rows = [ErrorMenuRowProtocol]()

        let seeMessageRow = generateActionRow(type: .seeMessage) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.handleSeeMessagePressed()
        }

        let copyMessageRow = generateActionRow(type: .copyMessage) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.handleCopyMessagePressed()
        }

        let closeNotificationRow = generateActionRow(type: .closeNotification) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.handleCloseNotification()
        }

        rows.append(seeMessageRow)
        rows.append(copyMessageRow)
        rows.append(closeNotificationRow)

        return rows
    }

    /// This method generates the action row.
    /// - Parameters:
    ///   - type: The type of row that needs to generate
    ///   - isDangerous: If the action that performs this row is dangerous. (E. g. Reset identities)
    ///   - action: The action to be performed
    private func generateActionRow(type: ErrorMenuViewModel.RowIdentifier,
                                   action: @escaping ActionBlock) -> ActionRow {
        guard let rowTitle = rowTitle(type: type) else {
            Log.shared.errorAndCrash(message: "Row title not found")
            return ActionRow(identifier: .seeMessage, title: "", action: nil, cellIdentifier: cellIdentifier)
        }
        return ActionRow(identifier: type, title: rowTitle, action: nil, cellIdentifier: cellIdentifier)
    }

    /// This method provides the title for each cell, regarding its type.
    ///
    /// - Parameter type: The row type to get the proper title
    /// - Returns: The title of the row. If it's an account row, it will be nil and the name of the account should be used.
    private func rowTitle(type : RowIdentifier) -> String? {
        switch type {
        case .closeNotification:
            return NSLocalizedString("Close notification",
                                     comment: "Error Menu: Cell (button) title to Close notification")
        case .copyMessage:
            return NSLocalizedString("Copy Message",
                                     comment: "Error Menu: Cell (button) title to Copy Message")
        case .seeMessage:
            return NSLocalizedString("See Message",
                                     comment: "Error Menu: Cell (button) title to See Message")
        }
    }

    private func handleSeeMessagePressed() {
        delegate?.showAlerView()
    }

    private func handleCopyMessagePressed() {
        guard let theErrorMessageToCopy = errorMessageToCopy else {
            Log.shared.errorAndCrash(error: "Error message not found")
            return
        }
        UIPasteboard.general.string = theErrorMessageToCopy
    }

    private func handleCloseNotification() {
        delegate?.closeNotification()
    }
}
