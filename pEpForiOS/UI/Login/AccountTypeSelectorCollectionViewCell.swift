//
//  AccountTypeSelectorCollectionViewCell.swift
//  pEp
//
//  Created by Xavier Algarra on 07/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Collection view cell class
class AccountTypeSelectorCollectionViewCell: UICollectionViewCell {

    @IBOutlet var imageToFill: UIImageView!
    
    /// adds an image loaded from the file name
    /// - Parameter fileName: file name to load
    func configure(withFileName fileName: String) {
        let image = UIImage(named: fileName)
        imageToFill.image = image
    }
    
    /// adds an image created from a text
    /// - Parameter text: source text
    func configure(withText text: String) {
        let image = text.image(color: UIColor.pEpGreen)
        imageToFill.image = image
    }
}
