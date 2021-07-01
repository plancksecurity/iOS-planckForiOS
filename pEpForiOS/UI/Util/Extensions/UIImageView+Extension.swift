//
//  UIImageView+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIImageView {
    /**
     - Returns: The aspect ratio, like 16:9, as a float. That is the factor you
     have to multiply the height and receive the width.
     */
    public func aspectRatio() -> CGFloat {
        return bounds.width / bounds.height
    }

    /**
     Sets up the necessary constraints to have the height always adopt to the width,
     while maintaining the correct aspect ratio.
     */
    public func activateAspectRatioConstraint() {
        let factor = 1 / aspectRatio()
        heightAnchor.constraint(equalTo: widthAnchor, multiplier: factor).isActive = true
    }

    /**
     Gives the image the uniform look of a contact image.
     */
    public func applyContactImageCornerRadius() {
        let theWidth = bounds.size.width
        layer.cornerRadius = round(theWidth / 10)
        layer.masksToBounds = true
    }

    /// Apply a border of the color passed by param.
    ///
    /// - Parameter color: The boder color
    public func applyBorder(color: UIColor) {
        layer.borderWidth = 2
        layer.borderColor = color.cgColor
    }

    /// Remove border if exists
    public func removeBorder() {
        layer.borderWidth = 0
        layer.borderColor = nil
    }
}
