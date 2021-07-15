//
//  UIImageView+ContactImage.swift
//  pEpForiOS
//
//  Created by Martín Brude on 14/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIImageView {

    /// Gives the image the uniform look of a contact image.
    public func applyContactImageCornerRadius() {
        let theWidth = bounds.size.width
        layer.cornerRadius = round(theWidth / 10)
        layer.masksToBounds = true
    }
}
