//
//  IdentityImageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

class IdentityImageOperation: Operation {
    /**
     The background color for the contact initials image.
     */
    let imageBackgroundColor = UIColor(hex: "#c8c7cc")

    /**
     The text color for the contact initials image.
     */
    let textColor = UIColor.white

    let identity: Identity
    let identityImageCache: NSCache<Identity, UIImage>

    /**
     The resulting image.
     */
    var image: UIImage?

    let imageSize: CGSize

    init(identity: Identity, imageSize: CGSize,
         identityImageCache: NSCache<Identity, UIImage>) {
        self.identity = identity
        self.imageSize = imageSize
        self.identityImageCache = identityImageCache
    }

    override func main() {
        if let img = identityImageCache.object(forKey: identity) {
            image = img
            return
        }

        if let theID = identity.userID {
            let ab = AddressBook()
            if let contact = ab.contactBy(userID: theID),
                let imgData = contact.thumbnailImageData {
                image = UIImage(data: imgData)
            }
        }
        if image == nil {
            var initials = "?"
            if let userName = identity.userName {
                initials = userName.initials()
            }
            image = identityImageFromName(initials: initials, size: imageSize)
        }

        if let img = image {
            identityImageCache.setObject(img, forKey: identity)
        }
    }

    fileprivate func drawCircle(ctx: CGContext, size: CGSize, color: UIColor) {
        let bgColor = color.cgColor
        ctx.setFillColor(bgColor)
        ctx.setStrokeColor(bgColor)
        let r = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        ctx.fillEllipse(in: r)
    }

    fileprivate func identityImageFromName(
        initials: String,
        size: CGSize, font: UIFont = UIFont.systemFont(ofSize: 24)) -> UIImage? {
        return UIImage.generate(size: size) { ctx in
            drawCircle(ctx: ctx, size: size, color: imageBackgroundColor)
            initials.draw(centeredIn: size, color: textColor, font: font)
        }
    }
}
