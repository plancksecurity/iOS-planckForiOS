//
//  UIImage+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIImage {
    /**
     Default size for avatar images.
     */
    open static let defaultAvatarSize = CGSize(width: 48, height: 48)

    open static func generate(size: CGSize, block: (CGContext) -> ()) -> UIImage? {
        var theImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        if let ctx = UIGraphicsGetCurrentContext() {
            block(ctx)
            theImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return theImage
    }
}
