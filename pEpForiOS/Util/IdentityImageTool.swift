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
import pEpUtilities

class IdentityImageTool {
    static private let queue = DispatchQueue.global(qos: .userInitiated)
    static private var _imageCache = [Identity:UIImage]()
    static private var imageCache: [Identity:UIImage] {
        get {
            var result = [Identity:UIImage]()
            queue.sync {
                result = _imageCache
            }
            return result
        }
        set {
            queue.sync {
                _imageCache = newValue
            }
        }
    }

    func clearCache() {
        IdentityImageTool.imageCache.removeAll()
    }

    func cachedIdentityImage(for identity: Identity) -> UIImage? {
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
                       textColor: UIColor = UIColor.white,
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
        if let safeImage = image {
            IdentityImageTool.imageCache[identity] = safeImage
        }
        return image
    }

    private func drawBackground(ctx: CGContext, size: CGSize, color: UIColor) {
        let r = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        let bgColor = color.cgColor
        ctx.setFillColor(bgColor)
        ctx.setStrokeColor(bgColor)
        ctx.fill(r)
    }

    private func identityImageFromName(initials: String, size: CGSize, textColor: UIColor,
                                       font: UIFont = UIFont.systemFont(ofSize: 24),
                                       imageBackgroundColor: UIColor) -> UIImage? {
        return UIImage.generate(size: size) { ctx, size in
            drawBackground(ctx: ctx, size: size, color: imageBackgroundColor)
            initials.draw(centeredIn: size, color: textColor, font: font)
        }
    }
}
