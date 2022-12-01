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
    /// The text to show
    var title: String { get }
    /// Indicates if the row is selected
    var isSelected: Bool { get }
}

class RecipientRow: RecipientRowProtocol {
    var cellIdentifier: String = "recipientCell"
    var title: String
    var isSelected: Bool

    init(title: String) {
        self.title = title
        self.isSelected = false // By default, the row is not selected
    }
}
