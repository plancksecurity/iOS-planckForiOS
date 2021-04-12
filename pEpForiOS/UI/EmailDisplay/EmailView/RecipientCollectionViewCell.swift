//
//  RecipientCollectionViewCell.swift
//  pEp
//
//  Created by Martín Brude on 12/4/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

class RecipientCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var recipientButton: UIButton!

    /// - Parameter text: The text to set
    func configure(withText text: String) {
        recipientButton.setTitle(text, for: .normal)
        recipientButton.titleLabel?.adjustsFontSizeToFitWidth = true
        if #available(iOS 13.0, *) {
            recipientButton.setTitleColor(UIColor.secondaryLabel, for: .normal)
        } else {
            recipientButton.setTitleColor(UIColor.lightGray, for: .normal)
        }
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let size = CGSize(width: bounds.size.width, height: 1)
        return contentView.systemLayoutSizeFitting(size)
    }

}


