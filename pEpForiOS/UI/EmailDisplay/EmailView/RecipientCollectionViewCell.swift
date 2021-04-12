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
        recipientButton.titleLabel?.textColor = UIColor.pEpGreen
        recipientButton.titleLabel?.adjustsFontSizeToFitWidth = true
        recipientButton.setTitle(text, for: .normal)
    }

}

