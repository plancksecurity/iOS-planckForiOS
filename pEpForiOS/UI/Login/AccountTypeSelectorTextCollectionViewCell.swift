//
//  AccountTypeSelectorTextCollectionViewCell.swift
//  pEp
//
//  Created by Xavier Algarra on 10/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class AccountTypeSelectorTextCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var textToFill: UILabel!
    
    /// adds an image created from a text
    /// - Parameter text: source text
    func configure(withText text: String) {
        textToFill.textColor = UIColor.pEpGreen
        textToFill.adjustsFontSizeToFitWidth = true
        textToFill.text = text
    }

}
