//
//  FlagImages.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 02/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

open class FlagImages {
    public static func create(imageSize: CGSize) -> FlagImages {
        let val = NSValue(cgSize: imageSize)
        if let o = sharedDict[val] {
            return o
        } else {
            let o = FlagImages(imageSize: imageSize)
            sharedDict[val] = o
            return o
        }
    }

    fileprivate static var sharedDict: [NSValue:FlagImages] = {
        let instance = [NSValue:FlagImages]()
        return instance
    }()

    let imageSize: CGSize

    public private(set) var flaggedImage: UIImage?
    public private(set) var notSeenImage: UIImage?
    public private(set) var flaggedAndNotSeenImage: UIImage?

    fileprivate init(imageSize: CGSize) {
        self.imageSize = imageSize
        createImages()
    }

    func createImages() {
        var circleSize = imageSize

        notSeenImage = createCircleImage(size: circleSize, color: .orange)
        circleSize.width -= 2
        circleSize.height -= 2
        let bufferCircle = createCircleImage(size: circleSize, color: .white)
        circleSize.width -= 2
        circleSize.height -= 2
        flaggedImage = createCircleImage(size: circleSize, color: .pEpBlue)

        flaggedAndNotSeenImage = createImageOverlay(
            size: circleSize, images: [flaggedImage, bufferCircle, notSeenImage])
    }

    func createImageOverlay(size: CGSize, images: [UIImage?]) -> UIImage? {
        return produceImage(size: size, block: { ctx in
            for img in images {
                if let theImg = img {
                    if let cg = theImg.cgImage {
                        var rect = CGRect(
                            x: 0.0, y: 0.0, width: theImg.size.width, height: theImg.size.height)
                        rect.origin.x = (size.width - theImg.size.width) / 2
                        rect.origin.y = (size.height - theImg.size.height) / 2
                        ctx.draw(cg, in: rect)
                    }
                }
            }
        })
    }

    func createCircleImage(size: CGSize, color: UIColor) -> UIImage? {
        return produceImage(size: size, block: { ctx in
            ctx.setFillColor(color.cgColor)
            ctx.setStrokeColor(color.cgColor)
            let center = CGPoint.init(x: size.width / 2, y: size.height / 2)
            let r = size.width / 2
            ctx.addArc(
                center: center, radius: r, startAngle: 0.0, endAngle: 1.0,
                clockwise: true)
            ctx.fillPath()
        })
    }

    func produceImage(size: CGSize, block: (CGContext) -> ()) -> UIImage? {
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

extension FlagImages {
    public func flagsImage(message: Message) -> UIImage? {
        let seen = message.imapFlags?.seen ?? false
        let flagged = message.imapFlags?.flagged ?? false

        if !seen && flagged {
            // show the overlay of the two states
            return flaggedAndNotSeenImage
        } else if flagged {
            return flaggedImage
        } else if !seen {
            return notSeenImage
        } else {
            return nil
        }
    }
}
