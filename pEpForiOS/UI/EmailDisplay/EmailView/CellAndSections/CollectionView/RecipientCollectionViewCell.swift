//
//  RecipientCollectionViewCell.swift
//  pEp
//
//  Created by Martín Brude on 21/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

class RecipientCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var recipientButton: RecipientButton!
    public static let cellId = "recipientCellId"

    func setup(cellVM: EmailViewModel.RecipientCollectionViewCellViewModel) {
        recipientButton.setup(text: cellVM.title, action: cellVM.action)
    }
}
