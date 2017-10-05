//
//  IdentityImageTool.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import AddressBook
import MessageModel

class IdentityImageTool {
    lazy var imageCache = NSCache<Identity, UIImage>()

    func clearCache() {
        imageCache.removeAllObjects()
    }

    func cachedIdentityImage(forIdentity identity: Identity) -> UIImage? {
        return imageCache.object(forKey: identity)
    }

    /// Creates (and caches) the contact image to display for an identity.
    /// This is a possibly time consuming process and shold not be called from the main thread.
    ///
    /// - Parameters:
    ///   - identity: identity to create contact image to doisplay for
    ///   - imageSize: size of the image to create
    ///   - textColor: text color to use in case the resulting images contains the users initials
    ///   - backgroundColor: backgroundcolor to use in case the resulting images contains the users initials
    /// - Returns: contact image to display
    func identityImage(for identity:Identity, imageSize: CGSize = CGSize.defaultAvatarSize, textColor: UIColor = UIColor.white,
                       backgroundColor: UIColor = UIColor(hex: "#c8c7cc")) -> UIImage? {
        var image:UIImage?
        if let cachedImage = imageCache.object(forKey: identity) {
            return cachedImage
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
            } else {
                let namePart = identity.address.namePartOfEmail()
                initials = namePart.initials()
            }
            image = identityImageFromName(initials: initials, size: imageSize, textColor: textColor,
                                          imageBackgroundColor: backgroundColor)
        }
        if let saveImage = image {
            imageCache.setObject(saveImage, forKey: identity)
        }
        return image
    }

    private func drawCircle(ctx: CGContext, size: CGSize, color: UIColor) {
        let bgColor = color.cgColor
        ctx.setFillColor(bgColor)
        ctx.setStrokeColor(bgColor)
        let r = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        ctx.fillEllipse(in: r)
    }

    private func identityImageFromName(initials: String, size: CGSize, textColor: UIColor,
                                       font: UIFont = UIFont.systemFont(ofSize: 24),
                                       imageBackgroundColor: UIColor) -> UIImage? {
        return UIImage.generate(size: size) { ctx in
            drawCircle(ctx: ctx, size: size, color: imageBackgroundColor)
            initials.draw(centeredIn: size, color: textColor, font: font)
        }
    }
}
