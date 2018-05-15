//
//  UIImage+GIF.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UIImage {
    struct AnimationFrame {
        let cgImg: CGImage
        let delayInCentiSeconds: Int
    }

    static func delayInCentiSeconds(cgImageSource: CGImageSource, atIndex index: Int) -> Int {
        var delay = 1

        if
            let properties: NSDictionary = CGImageSourceCopyPropertiesAtIndex(
                cgImageSource, index, nil),
            let gifProperties = properties.object(forKey: kCGImagePropertyGIFDictionary) as? NSDictionary {
            var numOptDelay = gifProperties.object(
                forKey: kCGImagePropertyGIFUnclampedDelayTime) as? NSNumber
            if (numOptDelay?.doubleValue ?? 0) == 0 {
                numOptDelay = gifProperties.object(forKey: kCGImagePropertyGIFDelayTime) as? NSNumber
            }
            if let numDelay = numOptDelay, numDelay.doubleValue > 0 {
                delay = lrint(numDelay.doubleValue * 100)
            }
        }

        return delay
    }

    static func createAnimationFrames(cgImageSource: CGImageSource) -> [AnimationFrame] {
        var animationFrames = [AnimationFrame]()
        let imgCount = CGImageSourceGetCount(cgImageSource)
        for index in 0..<imgCount {
            if let cgImg = CGImageSourceCreateImageAtIndex(cgImageSource, index, nil) {
                let delay = delayInCentiSeconds(cgImageSource: cgImageSource, atIndex: index)
                animationFrames.append(AnimationFrame(cgImg: cgImg, delayInCentiSeconds: delay))
            }
        }
        return animationFrames
    }

    /**
     Tries to create a gif from the given core foundation image source,
     that could possibly be animated.
     */
    public static func image(cgImageSource: CGImageSource) -> UIImage? {
        let imgCount = CGImageSourceGetCount(cgImageSource)
        if imgCount == 1 {
            if let cgImg = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) {
                return UIImage(cgImage: cgImg)
            } else {
                return nil
            }
        } else if imgCount > 1 {
            return nil
        } else {
            return nil
        }
    }

    /**
     Tries to create a gif from the given data, that could possibly
     be animated.
     */
    public static func image(gifData: Data) -> UIImage? {
        if let cfImgSource = CGImageSourceCreateWithData(gifData as CFData, nil) {
            return image(cgImageSource: cfImgSource)
        } else {
            return nil
        }
    }
}
