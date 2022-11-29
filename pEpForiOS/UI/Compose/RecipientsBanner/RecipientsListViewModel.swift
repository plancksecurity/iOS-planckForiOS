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

protocol RecipientsListViewDelegate: AnyObject {

    /// Reload the list and dismiss the view.
    func reloadAndDismiss()

    /// Reload the list
    func reload()
}

class RecipientsListViewModel {

    var composeViewModel: ComposeViewModel?
    weak var delegate: RecipientsListViewDelegate?

    private var rows = [RecipientRowProtocol]()

    /// Constructor
    /// - Parameters:
    ///   - recipients: The recipients to show in the list.
    init(recipients: [Identity], composeViewModel: ComposeViewModel) {
        self.rows = recipients.map {
            RecipientRow(address: $0.address)
        }
        self.composeViewModel = composeViewModel
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

    public func removeAll() {
        rows = []
        reloadAndDismiss()
    }

    public func removeRecipientsFrom(indexPaths: [IndexPath]) {
        guard let composeViewModel = composeViewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        indexPaths.forEach { ip in
            let index = ip.row
            let row = rows[index]
            // 1. Remove from this table view
            rows.remove(at: index)
            // 2. Remove from the state.
            composeViewModel.state.toRecipients.removeAll(where: {$0.address == row.address})
            composeViewModel.state.ccRecipients.removeAll(where: {$0.address == row.address})
            composeViewModel.state.bccRecipients.removeAll(where: {$0.address == row.address})
            // 3. Remove from the compose view

        }

        // 4. Reload.
        rows.count > 0 ? reload() : reloadAndDismiss()

    }

    private func reloadAndDismiss() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.delegate?.reloadAndDismiss()
        }
    }

    private func reload() {
        DispatchQueue.main.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.delegate?.reload()
        }
    }

}
