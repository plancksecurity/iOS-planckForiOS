//
//  UIImage+GIF.swift
//  pEp
//
//  Created by Dirk Zimmermann on 15.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UIImage {
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
        if let cgImgSource = CGImageSourceCreateWithData(gifData as CFData, nil) {
            return image(cgImageSource: cgImgSource)
        } else {
            return nil
        }
    }
}
