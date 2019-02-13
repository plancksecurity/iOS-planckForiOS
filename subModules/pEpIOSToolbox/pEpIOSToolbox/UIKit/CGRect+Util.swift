//
//  CGRect+Util.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 11.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension CGRect {
    public static func rectAround(center: CGPoint, width: CGFloat, height: CGFloat) -> CGRect {
        let origin = CGPoint(x: round(center.x - width / 2), y: round(center.y - height / 2))
        return CGRect(origin: origin, size: CGSize(width: width, height: height))
    }

    /**
     - Returns: A CGRect in the center of the receiver,
     with (width, height) <= (maxWidth, maxWidth).
     */
    public func centerRect(maxWidth: CGFloat) -> CGRect {
        let r = standardized
        var theWidth = maxWidth
        theWidth = min(theWidth, min(r.width, r.height))

        let widthR = round(r.width / 2)
        let centerX = r.origin.x + widthR

        let heightR = round(r.height / 2)
        let centerY = r.origin.y + heightR

        let center = CGPoint(x: centerX, y: centerY)

        let width2 = round(theWidth / 2)
        let origX = center.x - width2
        let origY = center.y - width2
        let orig = CGPoint(x: origX, y: origY)

        return CGRect(origin: orig, size: CGSize(width: theWidth, height: theWidth))
    }

    static public func rect(withWidth width: CGFloat, ratioOf size: CGSize) -> CGRect {
        let fixRatio = size.width / size.height
        let newHeight = width / fixRatio
        return CGRect(x: 0, y: 0, width: width, height: newHeight)
    }
}
