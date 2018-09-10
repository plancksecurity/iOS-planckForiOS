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
    static var imageCache = [Identity:UIImage]()

    let backgroundImage = UIImage(named: "pEp-status-green-disabled")

    func clearCache() {
        IdentityImageTool.imageCache.removeAll()
    }

    func cachedIdentityImage(forIdentity identity: Identity) -> UIImage? {
        return IdentityImageTool.imageCache[identity]
    }

    /// Creates (and caches) the contact image to display for an identity.
    /// This is a possibly time consuming process and shold not be called from the main thread.
    ///
    /// - Parameters:
    ///   - identity: identity to create contact image to doisplay for
    ///   - imageSize: size of the image to create
    ///   - textColor: text color to use in case the resulting images contains the users initials
    ///   - backgroundColor: backgroundcolor to use in case the resulting images contains
    ///     the users initials
    /// - Returns: contact image to display
    func identityImage(for identity:Identity,
                       imageSize: CGSize = CGSize.defaultAvatarSize,
                       textColor: UIColor = UIColor.black,
                       backgroundColor: UIColor = UIColor(hexString: "#c8c7cc")) -> UIImage? {
        var image:UIImage?
        if let cachedImage = IdentityImageTool.imageCache[identity] {
            return cachedImage
        }

        if let addressBookID = identity.addressBookID {
            let ab = AddressBook()
            if let contact = ab.contactBy(addressBookID: addressBookID),
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
            image = identityImageFromName(initials: initials,
                                          size: imageSize,
                                          textColor: textColor,
                                          imageBackgroundColor: backgroundColor)
        }
        if let saveImage = image {
            IdentityImageTool.imageCache[identity] = saveImage
        }
        return image
    }

    private func drawCircle(ctx: CGContext, size: CGSize, color: UIColor) {
        let r = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        if let cgImage = backgroundImage?.cgImage {
            ctx.draw(cgImage, in: r)
        } else {
            let bgColor = color.cgColor
            ctx.setFillColor(bgColor)
            ctx.setStrokeColor(bgColor)
            ctx.fillEllipse(in: r)
        }
    }

    private func identityImageFromName(initials: String, size: CGSize, textColor: UIColor,
                                       font: UIFont = UIFont.systemFont(ofSize: 24),
                                       imageBackgroundColor: UIColor) -> UIImage? {
        return UIImage.generate(size: size) { ctx, size in
            drawCircle(ctx: ctx, size: size, color: imageBackgroundColor)
            initials.draw(centeredIn: size, color: textColor, font: font)
        }
    }
}
