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
import pEpIOSToolbox

class IdentityImageTool {
    /// Key for the identity image cache dictionary.
    // Created to avoid accessing Identity's from a wrong queue.
    struct IdentityKey: Hashable {
        let userId: String?
        let address: String

        public static func ==(lhs: IdentityKey, rhs: IdentityKey) -> Bool {
            return lhs.address == rhs.address && lhs.userId == rhs.userId
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(address)
            hasher.combine(userId)
        }
    }
    static private let queue = DispatchQueue.global(qos: .userInitiated)
    static private var _imageCache = [IdentityKey:UIImage]()
    static private var imageCache: [IdentityKey:UIImage] {
        get {
            var result = [IdentityKey:UIImage]()
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
        var searchKey: IdentityKey? = nil
        let session = Session()
        session.performAndWait {
            let safeIdentity = identity.safeForSession(session)
            searchKey = IdentityKey(userId: safeIdentity.userID, address: safeIdentity.address)
        }
        guard let key = searchKey else {
            return nil
        }
        return IdentityImageTool.imageCache[key]
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
    func identityImage(for identity: Identity,
                       imageSize: CGSize = CGSize.defaultAvatarSize,
                       textColor: UIColor = UIColor.white,
                       backgroundColor: UIColor = UIColor(hexString: "#c8c7cc")) -> UIImage? {
        if let cachedImage = cachedIdentityImage(for: identity) {
            // We have the image in cache. Return it.
            return cachedImage
        }

        var image:UIImage?

        let session = Session()
        session.performAndWait { [weak self] in
            let safeIdentity = identity.safeForSession(session)

            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }

            if let addressBookID = safeIdentity.addressBookID {
                // Get image from system AddressBook is any
                let ab = AddressBook()
                if let contact = ab.contactBy(addressBookID: addressBookID),
                    let imgData = contact.thumbnailImageData {
                    image = UIImage(data: imgData)
                }
            }

            if image == nil {
                // We cound not find an image anywhere. Let's create one with the initials
                var initials = "?"
                if let userName = safeIdentity.userName {
                    initials = userName.initials()
                } else {
                    let namePart = safeIdentity.address.namePartOfEmail()
                    initials = namePart.initials()
                }
                image =  me.identityImageFromName(initials: initials,
                                              size: imageSize,
                                              textColor: textColor,
                                              imageBackgroundColor: backgroundColor)
            }
            if let safeImage = image {
                // cache image
                let saveKey = IdentityKey(userId: safeIdentity.userID, address: safeIdentity.address)
                IdentityImageTool.imageCache[saveKey] = safeImage
            }
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
