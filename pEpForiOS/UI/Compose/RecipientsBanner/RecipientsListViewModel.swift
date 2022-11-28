//
//  RecipientsListViewModel.swift
//  pEpForiOS
//
//  Created by Martín Brude on 18/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

class RecipientsListViewModel {

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
}
