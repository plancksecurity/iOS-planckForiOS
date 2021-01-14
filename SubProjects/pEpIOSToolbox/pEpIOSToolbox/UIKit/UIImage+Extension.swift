//
//  UIImage+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension UIImage {
    public static func generate(size: CGSize, block: (CGContext, CGSize) -> ()) -> UIImage? {
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
    public static func pixel(color: UIColor) -> UIImage? {
        let pixelScale = UIScreen.main.scale
        let pixelSize = 1 / pixelScale
        let fillSize = CGSize(width: pixelSize, height: pixelSize)
        return generate(size: fillSize) { context, size in
            let fillRect = CGRect(origin: CGPoint.zero, size: size)
            context.setFillColor(color.cgColor)
            context.fill(fillRect)
        }
    }

    /// Returns the image resized to the given width, using scaleToFit behaviour.
    ///
    /// - Parameters:
    ///   - newWidth:   target width the image should be resized to
    ///   - useAlpha:   A Boolean flag indicating whether the bitmap must include an alpha channel
    ///                 (to handle any partially transparent pixels). If you know the bitmap is
    ///                 fully opaque, specify false to ignore the alpha channel and optimize the
    ///                 bitmap’s storage.
    ///   - scale:      The scale factor to apply to the bitmap.
    ///                 If you specify a value of 0.0, the scale factor is set to the scale factor of the device’s main screen.
    /// - Returns: resized image
    public func resized(newWidth: CGFloat, useAlpha: Bool = true, scale: CGFloat = 0.0) -> UIImage? {
        let factor = self.size.width / newWidth
        let size = CGSize(width: self.size.width / factor, height: self.size.height / factor)
        let opaque = !useAlpha
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        return newImage
    }
}
