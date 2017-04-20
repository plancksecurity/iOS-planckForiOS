//
//  CGRect+Util.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension CGRect {
    static func rectAround(center: CGPoint, width: CGFloat, height: CGFloat) -> CGRect {
        let origin = CGPoint(x: round(center.x - width / 2), y: round(center.y - height / 2))
        return CGRect(origin: origin, size: CGSize(width: width, height: height))
    }

    /**
     - Returns: A CGRect in the center of the receiver,
     with (width, height) <= (maxWidth, maxWidth).
     */
    func centerRect(maxWidth: CGFloat) -> CGRect {
        let r = standardized
        var theWidth = maxWidth
        theWidth = min(theWidth, min(r.width, r.height))
        let center = CGPoint(x: r.origin.x + round(r.width / 2),
                             y: r.origin.y + round(r.height / 2))
        let orig = CGPoint(x: center.x - round(theWidth / 2), y: center.y - round(theWidth / 2))
        return CGRect(origin: orig, size: CGSize(width: theWidth, height: theWidth))
    }
}
