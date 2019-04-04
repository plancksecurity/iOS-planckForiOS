//
//  FlagImages.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 02/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

class FlagImages {
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

    private static var sharedDict: [NSValue:FlagImages] = {
        let instance = [NSValue:FlagImages]()
        return instance
    }()

    let imageSize: CGSize

    public private(set) var flaggedImage: UIImage?
    public private(set) var notSeenImage: UIImage?
    public private(set) var flaggedAndNotSeenImage: UIImage?
    public private(set) var toMeImage: UIImage?
    public private(set) var toMeCcImage: UIImage?

    private init(imageSize: CGSize) {
        self.imageSize = imageSize
        createImages()
    }

    func createImages() {
        var size = imageSize
        let textTo = NSLocalizedString("TO", comment: "to me image text") as NSString
        let textToCc = NSLocalizedString("CC", comment: "to me image text") as NSString
        flaggedImage = createCircleImage(size: size, color: .orange)
        notSeenImage = createCircleImage(size: size, color: .blue)
        toMeImage = createSquareImage(size: textTo.size(), color: .lightGray, text: textTo)
        toMeCcImage = createSquareImage(size: textToCc.size(), color: .lightGray, text: textToCc)

        size.width -= 5
        size.height -= 5
        let flaggedImageSmall = createCircleImage(size: size, color: .orange)

        flaggedAndNotSeenImage = createImageOverlay(
            size: imageSize, images: [notSeenImage, flaggedImageSmall])
    }

    func createImageOverlay(size: CGSize, images: [UIImage?]) -> UIImage? {
        return produceImage(size: size, block: { ctx in
            for img in images {
                if let theImg = img {
                    if let cg = theImg.cgImage {
                        var rect = CGRect(
                            x: 0.0, y: 0.0, width: theImg.size.width, height: theImg.size.height)
                        rect.origin.x = round((size.width - theImg.size.width) / 2)
                        rect.origin.y = round((size.height - theImg.size.height) / 2)
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
            let r = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size)
            ctx.fillEllipse(in: r)
        })
    }

    func createSquareImage(size: CGSize, color: UIColor, text: NSString) -> UIImage? {
        let finalsize = CGSize(width: size.width+2.0, height: size.height)
        let image = produceImage(size: finalsize, block: { ctx in
            ctx.setFillColor(color.cgColor)
            ctx.setStrokeColor(color.cgColor)
            let r = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size)
            let path = UIBezierPath(roundedRect: r, cornerRadius: 2.5)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
        })
        return addTextToImage(image: image, text: text)
    }
    
    func addTextToImage(image: UIImage?, text: NSString) -> UIImage? {
        let textFontAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 10)!,
            NSAttributedString.Key.foregroundColor: UIColor.white,
            ] 
        
        UIGraphicsBeginImageContextWithOptions((image?.size)!, false, 0.0)
        image?.draw(in: CGRect(origin: CGPoint.zero, size: (image?.size)!))
        let rect = CGRect(origin: CGPoint(x: 1, y: 1), size: (image?.size)!)
        text.draw(in: rect, withAttributes: textFontAttributes)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
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
        let flagged = message.imapFlags?.flagged ?? false
        if flagged {
            return flaggedImage
        } else {
            return nil
        }
    }
}
