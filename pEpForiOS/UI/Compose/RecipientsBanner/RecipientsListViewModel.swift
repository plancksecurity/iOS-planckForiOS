//
//  RecipientsListViewModel.swift
//  pEpForiOS
//
//  Created by Martín Brude on 18/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

protocol RecipientListViewModelDelegate: AnyObject {

    /// Remove the recipients with the given username or address from the state
    /// - Parameter addresses: The addresses of the recipients.
    func removeFromState(addresses: [String])
}

protocol RecipientsListViewDelegate: AnyObject {

    /// Reload the list and dismiss the view.
    func reloadAndDismiss()
}

class RecipientsListViewModel {

    weak var viewModelDelegate: RecipientListViewModelDelegate?
    weak var delegate: RecipientsListViewDelegate?

    private var rows = [RecipientRowProtocol]()

    /// Constructor
    /// - Parameters:
    ///   - recipients: The recipients to show in the list.
    ///   - recipientListViewModelDelegate: The  view model delegate
    init(recipients: [Identity], viewModelDelegate: RecipientListViewModelDelegate) {
        self.rows = recipients.uniques.map {
            RecipientRow(username: $0.userName, address: $0.address)
        }
        self.viewModelDelegate = viewModelDelegate
    }

    /// Number of rows
    public var numberOfRows: Int {
        return rows.count
    }

    /// Description that explains the current view. 
    public var description: String {
        return NSLocalizedString("Unable to send message securely. Please consider removing the following recipients for a secure transmission of this email:", comment: "Warning description")
    }

    /// Retrieves the row
    subscript(index: Int) -> RecipientRowProtocol {
        get {
            return rows[index]
        }
    }

    /// Remove all the recipients
    public func removeAll() {
        guard let viewModelDelegate = viewModelDelegate else {
            Log.shared.errorAndCrash("composeViewModelDelegate not found")
            return
        }
        viewModelDelegate.removeFromState(addresses: rows.map { $0.address} )
        reloadAndDismiss()
    }
}

// MARK: - Private

extension RecipientsListViewModel {
    private func reloadAndDismiss() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.delegate?.reloadAndDismiss()
        }
    }
}
