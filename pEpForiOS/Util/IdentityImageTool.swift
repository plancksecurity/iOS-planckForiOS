//
//  IdentityImageTool.swift
//  pEp
//
//  Created by Andreas Buff on 02.10.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import AddressBook

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

extension IdentityImageTool {
    /// Key for the identity image cache dictionary.
    // Created to avoid accessing Identity's from a wrong queue.
    struct IdentityKey: Hashable {
        let userId: String?
        let address: String
        let addressBookId: String?
        let userName: String?

        init(identity: Identity) {
            userId = identity.userID
            address = identity.address
            addressBookId = identity.addressBookID
            userName = identity.userName
        }

        // MARK: Hashable

        public static func ==(lhs: IdentityKey, rhs: IdentityKey) -> Bool {
            return lhs.address == rhs.address && lhs.userId == rhs.userId
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(address)
            hasher.combine(userId)
        }
    }
}

// MARK: - ChacheObject

extension IdentityImageTool {
    struct CacheObject: Hashable {
        let image: UIImage
        let cnContactHasBeenTakenIntoAccount: Bool
    }

}

class IdentityImageTool {
    static private let cacheAccessSyncQueue = DispatchQueue(label: "security.pep.IdentityImageTool.chacheSyncQueue",
                                                            qos: .userInitiated)
    static private var _imageCache = [IdentityKey:CacheObject]()
    static private var imageCache: [IdentityKey:CacheObject] {
        get {
            var result = [IdentityKey:CacheObject]()
            cacheAccessSyncQueue.sync {
                result = _imageCache
            }
            return result
        }
        set {
            cacheAccessSyncQueue.sync {
                _imageCache = newValue
            }
        }
    }

    func clearCache() {
        IdentityImageTool.imageCache.removeAll()
    }

    static func clearCache() {
        IdentityImageTool.imageCache.removeAll()
    }

    func cachedIdentityImage(for key: IdentityKey) -> UIImage? {
        guard let cache = IdentityImageTool.imageCache[key] else {
            return nil
        }
        if
            let cache = IdentityImageTool.imageCache[key],
            let _ = key.addressBookId, !cache.cnContactHasBeenTakenIntoAccount {
            // The cache holds image that is not from contacts, but we have a CNContact.identifier
            // now. Invalidate cache and try to get image from contacts.
            IdentityImageTool.imageCache.removeValue(forKey: key)
            return nil
        }
        return cache.image
    }

    func identityImage(for identityKey: IdentityKey,
                       imageSize: CGSize = CGSize.defaultAvatarSize,
                       textColor: UIColor? = nil,
                       backgroundColor: UIColor = UIColor(hexString: "#c8c7cc")) -> UIImage? {

        /// If the text color is passed by parameter, let's use it.
        /// Otherwise, evaluate if dark mode is on: in that case use pEpBlack, else, white.
        var textColorToSet = UIColor.white
        if textColor == nil {
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    textColorToSet = UIColor.pEpBlack
                } else {
                    textColorToSet = UIColor.white
                }
            }
        }

        if let cachedImage = cachedIdentityImage(for: identityKey) {
            // We have the image in cache. Return it.
            return cachedImage
        }

        var image: UIImage?
        var contactHasBeenCheckedForImage = false
        if let addressBookID = identityKey.addressBookId {
            // Get image from system AddressBook if any
            if let contact = AddressBook.contactBy(addressBookID: addressBookID),
                let imgData = contact.thumbnailImageData {
                image = UIImage(data: imgData)
            }
            contactHasBeenCheckedForImage = true
        }

        if image == nil {
            // We couldn't find an image, so we create one with the initials.
            if let nameInitials = identityKey.userName?.initials() {
                image = identityImageFromName(initials: nameInitials,
                size: imageSize,
                textColor: textColorToSet,
                imageBackgroundColor: backgroundColor)
            } else {
                image = UIImage(named: "pEpforiOS-avatar")
            }
        }
        if let safeImage = image {
            // save image to cache
            IdentityImageTool.imageCache[identityKey] =
                IdentityImageTool.CacheObject(image: safeImage, cnContactHasBeenTakenIntoAccount: contactHasBeenCheckedForImage)
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
