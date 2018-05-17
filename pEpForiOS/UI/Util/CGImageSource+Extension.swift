//
//  CGImageSource+Extension.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension CGImageSource {
    /**
     Every image contained in this source interpreted as animation frame,
     together with its duration.
     */
    struct AnimationFrame {
        /** The image representing this frame */
        let cgImage: CGImage

        /** The duration of that frame, in milliseconds */
        let durationMillis: Double

        /** The duration of that frame, in deciseconds */
        let durationDecis: Int64
    }

    /**
     Determines the time of a contained frame, in milliseconds.
     - Returns: The time the image at the given index should be shown, in milliseconds.
     - Note: The index is not checked for validity.
     */
    func frameTimeMillis(cgImageSource: CGImageSource, atIndex index: Int) -> Double {
        var frameTimeMilliSeconds: Double = 0

        if
            let properties: NSDictionary = CGImageSourceCopyPropertiesAtIndex(
                cgImageSource, index, nil),
            let gifProperties = properties.object(forKey: kCGImagePropertyGIFDictionary)
                as? NSDictionary
        {
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

    /**
     Looks up the image at the given index.
     - Returns: The `CGImage` contained at the given index.
     - Note: The index is not checked for validity.
     */
    func cgImage(atIndex: Int) -> CGImage? {
        return CGImageSourceCreateImageAtIndex(self, atIndex, nil)
    }

    /**
     Delivers the `AnimationFrame`s.
     - Returns: All contained `AnimationFrame`s
     */
    func animationFrames() -> [AnimationFrame] {
        var animationFrames = [AnimationFrame]()
        let imgCount = CGImageSourceGetCount(self)
        for index in 0..<imgCount {
            if let cgImg = cgImage(atIndex: index) {
                let frameDurationMillis = frameTimeMillis(cgImageSource: self, atIndex: index)
                let frameDurationDecis = Int64((frameDurationMillis * 100).rounded())
                animationFrames.append(AnimationFrame(
                    cgImage: cgImg,
                    durationMillis: frameDurationMillis,
                    durationDecis: frameDurationDecis))
            }
        }
        return animationFrames
    }
}
