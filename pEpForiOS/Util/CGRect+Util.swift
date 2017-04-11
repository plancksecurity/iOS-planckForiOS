//
//  CGRect+Util.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension CGRect {
    /**
     - Returns: A CGRect in the center of the receiver,
     with (width, height) <= (maxWidth, maxWidth).
     */
    func centerRect(maxWidth: CGFloat) -> CGRect {
        let r = standardized
        var theWidth = maxWidth
        theWidth = min(theWidth, min(r.width, r.height))
        let center = CGPoint(x: r.origin.x + r.width / 2, y: r.origin.y + r.height / 2)
        let orig = CGPoint(x: center.x - theWidth / 2, y: center.y - theWidth / 2)
        return CGRect(origin: orig, size: CGSize(width: theWidth, height: theWidth))
    }
}
