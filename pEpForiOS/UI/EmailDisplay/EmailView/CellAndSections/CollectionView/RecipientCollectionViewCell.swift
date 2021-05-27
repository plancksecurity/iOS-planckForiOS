//
//  RecipientCollectionViewCell.swift
//  pEp
//
//  Created by Martín Brude on 21/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

class RecipientCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var recipientButton: RecipientButton!
    public static let cellId = "recipientCellId"

    func setup(with collectionViewCellViewModel: EmailViewModel.CollectionViewCellViewModel) {
        var color: UIColor = .darkText
        switch collectionViewCellViewModel.recipientType {
        case .to, .cc, .bcc:
            recipientButton.setPEPFont(style: .footnote, weight: .regular)
            color = UIColor.pEpSecondaryColor()
        case .from:
            recipientButton.setPEPFont(style: .headline, weight: .semibold)
            color = UIColor.pEpLabelColor()
        }
        recipientButton.setup(text: collectionViewCellViewModel.title,
                              color: color,
                              action: collectionViewCellViewModel.action)
    }
}
