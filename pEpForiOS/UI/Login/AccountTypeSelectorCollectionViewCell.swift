//
//  AccountTypeSelectorCollectionViewCell.swift
//  pEp
//
//  Created by Xavier Algarra on 07/02/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

/// Collection view cell class
class AccountTypeSelectorImageCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageToFill: UIImageView!
    
    /// adds an image loaded from the file name
    /// - Parameter fileName: file name to load
    func configure(withFileName fileName: String) {
        let image = UIImage(named: fileName)
        imageToFill.image = image
    }
}
