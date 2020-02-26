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

        if animationFrames.count == 1 {
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
}
