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
     Default size for avatar images. Should also match storyboard sizes.
     */
    open static let defaultAvatarSize = CGSize(width: 48, height: 48)

    /**
     Default size for pEp rating image in avatar images.
     Related with `defaultAvatarSize`, and should be smaller.
     Should also match storyboard sizes.
     */
    open static let defaultAvatarPEPStatusSize = CGSize(width: 20, height: 20)

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
