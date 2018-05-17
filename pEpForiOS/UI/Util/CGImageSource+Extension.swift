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

        /** The duration of that frame, in seconds */
        let durationSeconds: Double

        /** The duration of that frame, in deciseconds */
        let durationDecis: Int64

        /**
         Greatest common denominator of two `Int64`s.
         */
        static func gcd(int641: Int64, int642: Int64) -> Int64 {
            if int641 < int642 {
                return gcd(int641: int642, int642: int641)
            }
            var num1 = int641
            var num2 = int642
            while true {
                let r = num1 % num2
                if r == 0 {
                    return num2
                }
                num1 = num2
                num2 = r
            }
        }

        /**
         Greatest common denominator of an array of `Int64`s.
         */
        static func gcd(int64s: [Int64]) -> Int64? {
            if int64s.isEmpty || int64s.count < 2 {
                return nil
            }

            var theGcd = int64s[0]
            for value in int64s {
                theGcd = gcd(int641: value, int642: theGcd)
            }

            return theGcd
        }

        /**
         Greatest common denominator of an array of `Int64`s.
         */
        static func gcd(animationFrames: [AnimationFrame]) -> Int64? {
            let theInts = animationFrames.map { return $0.durationDecis }
            return gcd(int64s: theInts)
        }

        /**
         Total duration in milliseconds of a sequence of animation frames.
         */
        static func totalDurationSeconds(animationFrames: [AnimationFrame]) -> Double {
            let durations = animationFrames.map { return $0.durationSeconds }
            return durations.reduce(0) { accu, theNextDouble in
                return accu + theNextDouble
            }
        }

        /**
         Total duration in deciseconds of a sequence of animation frames.
         */
        static func totalDurationDecis(animationFrames: [AnimationFrame]) -> Int64 {
            let durations = animationFrames.map { return $0.durationDecis }
            return durations.reduce(0) { accu, theNextInt64 in
                return accu + theNextInt64
            }
        }
    }

    /**
     Determines the time of a contained frame, in seconds.
     - Returns: The time the image at the given index should be shown, in milliseconds.
     - Note: The index is not checked for validity.
     */
    func frameTimeSeconds(cgImageSource: CGImageSource, atIndex index: Int) -> Double {
        var theFrameTimeSeconds: Double = 0

        if
            let properties: NSDictionary = CGImageSourceCopyPropertiesAtIndex(
                cgImageSource, index, nil),
            let gifProperties = properties.object(forKey: kCGImagePropertyGIFDictionary)
                as? NSDictionary
        {
            if let numDelayUnclamped = gifProperties.object(
                forKey: kCGImagePropertyGIFUnclampedDelayTime) as? NSNumber {
                theFrameTimeSeconds = numDelayUnclamped.doubleValue
            }

            if theFrameTimeSeconds == 0,
                let numDelayClamped = gifProperties.object(forKey: kCGImagePropertyGIFDelayTime)
                    as? NSNumber {
                theFrameTimeSeconds = numDelayClamped.doubleValue
                if theFrameTimeSeconds <= 0.050 { // 50 milliseconds or less?
                    theFrameTimeSeconds = 0.1 // clamp to 100 milliseconds
                }
            }
        }

        return theFrameTimeSeconds
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
                let frameDurationSeconds = frameTimeSeconds(cgImageSource: self, atIndex: index)
                let frameDurationDecis = Int64((frameDurationSeconds * 100).rounded())
                animationFrames.append(AnimationFrame(
                    cgImage: cgImg,
                    durationSeconds: frameDurationSeconds,
                    durationDecis: frameDurationDecis))
            }
        }
        return animationFrames
    }
}
