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
    func aspectRatio() -> CGFloat {
        return bounds.width / bounds.height
    }

    /**
     Sets up the necessary constraints to have the height always adopt to the width,
     while maintaining the correct aspect ratio.
     */
    func activateAspectRatioConstraint() {
        let factor = 1 / aspectRatio()
        heightAnchor.constraint(equalTo: widthAnchor, multiplier: factor).isActive = true
    }
}
