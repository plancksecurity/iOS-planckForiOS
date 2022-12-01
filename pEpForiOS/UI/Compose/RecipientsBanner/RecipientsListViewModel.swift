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
        self.rows = recipients.uniques.map {
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
        var ips = [IndexPath]()
        for i in 0...rows.count {
            let ip = IndexPath(row: i, section: 0)
            ips.append(ip)
        }
        removeRecipientsFrom(indexPaths: ips)
    }

    public func removeRecipientsFrom(indexPaths: [IndexPath]) {
        guard let composeViewModel = composeViewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }

        //MB:- improve this.
        let rowEnumeration = rows.enumerated()
        let rowsToDelete = rowEnumeration
            .filter { indexPaths.map({$0.row}).contains($0.offset) }
            .map { $0.element }

        composeViewModel.removeFromState(addresses: rowsToDelete.map({$0.address}))

        rows = rowEnumeration
            .filter { !indexPaths.map({$0.row}).contains($0.offset) }
            .map { $0.element }

        // 3. Reload.
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
