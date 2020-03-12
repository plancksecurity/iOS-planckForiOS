//
//  UIImage+GIF.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import Foundation

extension UIImage {
    private struct Constant {
        // Fast bug fix related to bug IOS-1696 (large) animated gif causes iOS app to crash (5oo-520 frames with resolution ~1100x800  needed ~1.8GB RAM)
        static let maxAllowedFrames = 60
    }

    static func image(animationFrames: [CGImageSource.AnimationFrame]) -> UIImage? {
        if animationFrames.isEmpty {
            return nil
        }

        let totalSeconds = animationFrames.reduce(0) { acc, next in
            return acc + next.durationSeconds
        }

        guard let gcdDecis = CGImageSource.AnimationFrame.gcdDurationDecis(
            animationFrames: animationFrames) else {
                return nil
        }

        let parts = animationFrames.map { $0.durationDecis / gcdDecis }

        var images = [UIImage]()

        for iPart in 0..<parts.count {
            let frameImage = UIImage(cgImage: animationFrames[iPart].cgImage)
            let numberOfImagesNeeded = parts[iPart]
            for _ in 0..<numberOfImagesNeeded {
                images.append(frameImage)
            }
        }

        return UIImage.animatedImage(with: images, duration: totalSeconds)
    }

    /**
     Tries to create a gif from the given core foundation image source,
     that could possibly be animated.
     */
    public static func image(cgImageSource: CGImageSource) -> UIImage? {
        let animationFrames = cgImageSource.animationFrames()

        if animationFrames.count == 1 || animationFrames.count > Constant.maxAllowedFrames {
            let frame1 = animationFrames[0]
            return UIImage(cgImage: frame1.cgImage)
        } else if animationFrames.count > 1 {
             return image(animationFrames: animationFrames)
        } else {
            return nil
        }
    }

    /**
     Tries to create a gif from the given data, that could possibly
     be animated.
     */
    public static func image(gifData: Data) -> UIImage? {
        if let cgImgSource = CGImageSourceCreateWithData(gifData as CFData, nil) {
            return image(cgImageSource: cgImgSource)
        } else {
            return nil
        }
    }
    
    /// Method that resize the image that invokes and returns a new one.
    /// - Parameter targetSize: The desired size of the image.
    public func resizeImage(targetSize: CGSize) -> UIImage? {

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}


