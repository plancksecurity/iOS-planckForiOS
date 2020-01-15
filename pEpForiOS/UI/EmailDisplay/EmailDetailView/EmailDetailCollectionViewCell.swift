//
//  EmailDetailCollectionViewCell.swift
//  pEp
//
//  Created by Andreas Buff on 10.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class EmailDetailCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var containerView: UIView!

    override func prepareForReuse() {
        // Remove the previously shown EmailViewController view
        containerView.subviews.forEach { $0.removeFromSuperview() }
    }
}
