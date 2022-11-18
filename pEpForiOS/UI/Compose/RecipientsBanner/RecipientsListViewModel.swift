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

    private var rows = [RedRecipientRowProtocol]()

    init(recipients: [Identity]) {
        self.rows = recipients.map {
            RedRecipientRow(address: $0.address)
        }
    }

    /// Number of rows
    public var numberOfRows: Int {
        return rows.count
    }

    /// Retrieves the row
    subscript(index: Int) -> RedRecipientRowProtocol {
        get {
            return rows[index]
        }
    }
}
