//
//  RecipientRowProtocol.swift
//  pEpForiOS
//
//  Created by Martín Brude on 18/11/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

protocol RecipientRowProtocol {
    /// The cell identifier
    var cellIdentifier: String { get }
    /// The username to show
    var username: String? { get }
    /// The address to show
    var address: String { get }
    /// Indicates if the row is selected
    var isSelected: Bool { get }
}

class RecipientRow: RecipientRowProtocol {
    var cellIdentifier: String = "recipientCell"
    var username: String?
    var address: String
    var isSelected: Bool

    init(username: String? = nil, address: String) {
        self.username = username
        self.address = address
        self.isSelected = false // By default, the row is not selected
    }
}
