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
        let frameTime: Double // The time of that frame, in milliseconds
    }

    /**
     Determines the time of a frame, in milliseconds.
     */
    static func frameTime(cgImageSource: CGImageSource, atIndex index: Int) -> Double {
        var frameTimeMilliSeconds: Double = 0

        if
            let properties: NSDictionary = CGImageSourceCopyPropertiesAtIndex(
                cgImageSource, index, nil),
            let gifProperties = properties.object(forKey: kCGImagePropertyGIFDictionary)
                as? NSDictionary {

            if let numDelayUnclamped = gifProperties.object(
                forKey: kCGImagePropertyGIFUnclampedDelayTime) as? NSNumber {
                frameTimeMilliSeconds = numDelayUnclamped.doubleValue
            }

            if frameTimeMilliSeconds == 0,
                let numDelayClamped = gifProperties.object(forKey: kCGImagePropertyGIFDelayTime)
                    as? NSNumber {
                frameTimeMilliSeconds = numDelayClamped.doubleValue
                if frameTimeMilliSeconds <= 0.005 {
                    frameTimeMilliSeconds = 100
                }
            }
        }

        return frameTimeMilliSeconds
    }

    static func createAnimationFrames(cgImageSource: CGImageSource) -> [AnimationFrame] {
        var animationFrames = [AnimationFrame]()
        let imgCount = CGImageSourceGetCount(cgImageSource)
        for index in 0..<imgCount {
            if let cgImg = CGImageSourceCreateImageAtIndex(cgImageSource, index, nil) {
                let delay = frameTime(cgImageSource: cgImageSource, atIndex: index)
                animationFrames.append(AnimationFrame(cgImg: cgImg, frameTime: delay))
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
