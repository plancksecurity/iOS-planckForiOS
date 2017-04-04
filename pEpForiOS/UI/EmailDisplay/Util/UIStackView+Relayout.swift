//
//  UIStackView+Relayout.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

extension UIStackView {
    /**
     Resizes all arranged views so they have the same width.
     */
    func reLayout(width: CGFloat) -> CGFloat {
        if arrangedSubviews.count == 0 {
            return 0
        }
        var totalHeight: CGFloat = 0
        for v in arrangedSubviews {
            let origWidth = v.bounds.width
            if origWidth > width {
                let origHeight = v.bounds.height
                let newHeight = floor(width / origWidth * origHeight)
                v.frame.size = CGSize(width: width, height: newHeight)
                v.frame.origin = CGPoint.zero
            }
            totalHeight += v.bounds.size.height
        }
        totalHeight = totalHeight + CGFloat(arrangedSubviews.count - 1) * spacing
        frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: totalHeight))
        layoutIfNeeded()
        return totalHeight
    }
}
