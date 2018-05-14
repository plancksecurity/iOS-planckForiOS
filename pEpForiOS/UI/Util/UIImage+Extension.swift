//
//  UIImage+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIImage {
    open static func generate(size: CGSize, block: (CGContext, CGSize) -> ()) -> UIImage? {
        var theImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        if let ctx = UIGraphicsGetCurrentContext() {
            block(ctx, size)
            theImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return theImage
    }

    /**
     - Create a 1x1 pixel image of the given color.
     - Note: Retina-displays are taken into account.
     - Returns: An image that contains exactly one pixel of the given color.
     */
    open static func pixel(color: UIColor) -> UIImage? {
        let pixelScale = UIScreen.main.scale
        let pixelSize = 1 / pixelScale
        let fillSize = CGSize(width: pixelSize, height: pixelSize)
        return generate(size: fillSize) { context, size in
            let fillRect = CGRect(origin: CGPoint.zero, size: size)
            context.setFillColor(color.cgColor)
            context.fill(fillRect)
        }
    }

    public func resized(newWidth: CGFloat) -> UIImage? {
        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
