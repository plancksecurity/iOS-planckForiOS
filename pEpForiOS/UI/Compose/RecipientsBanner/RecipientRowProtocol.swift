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
}

protocol RedRecipientRowProtocol: RecipientRowProtocol {
    var address: String { get }
    var isSelected: Bool { get }
}

class RedRecipientRow: RedRecipientRowProtocol {
    var cellIdentifier: String = "redRecipientCell"
    var address: String
    var isSelected: Bool

    init(address: String) {
        self.address = address
        self.isSelected = false
    }
}

