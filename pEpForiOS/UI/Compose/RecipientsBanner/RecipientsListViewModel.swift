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

    func reload()

    func reloadAndDismiss()
}

class RecipientsListViewModel {

    weak var delegate: RecipientsListViewDelegate?

    private var rows = [RecipientRowProtocol]()

    /// Constructor
    /// - Parameters:
    ///   - recipients: The recipients to show in the list.
    init(recipients: [Identity]) {
        self.rows = recipients.map {
            RecipientRow(address: $0.address)
        }
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

    public func removeRecipientsFrom(indexPaths: [IndexPath]) {
        indexPaths.forEach { ip in
            rows.remove(at: ip.row)
        }
        rows.count > 0 ? reload() : reloadAndDismiss()
    }

    public func removeAll() {
        rows = []
        reloadAndDismiss()
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
