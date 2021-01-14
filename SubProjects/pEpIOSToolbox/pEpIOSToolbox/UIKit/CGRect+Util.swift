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

    static public func rect(withWidth width: CGFloat, ratioOf size: CGSize) -> CGRect {
        let fixRatio = size.width / size.height
        let newHeight = width / fixRatio
        return CGRect(x: 0, y: 0, width: width, height: newHeight)
    }
}
