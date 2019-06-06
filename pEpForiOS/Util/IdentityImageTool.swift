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

class IdentityImageTool {
    static private let cacheAccessSyncQueue = DispatchQueue(label: "security.pep.IdentityImageTool.chacheSyncQueue",
                                                            qos: .userInitiated)
    static private var _imageCache = [IdentityKey:UIImage]()
    static private var imageCache: [IdentityKey:UIImage] {
        get {
            var result = [IdentityKey:UIImage]()
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

    //    func cachedIdentityImage(for identity: Identity) -> UIImage? { //!!!: cleanup
//        var searchKey: IdentityKey? = nil
//        let session = Session()
//        session.performAndWait {
//            let safeIdentity = identity.safeForSession(session)
//            searchKey = IdentityKey(identity: safeIdentity)
//        }
//        guard let key = searchKey else {
//            return nil
//        }
//        return IdentityImageTool.imageCache[key]
//    }

    func cachedIdentityImage(for key: IdentityKey) -> UIImage? {
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
//    func identityImage(for identity: Identity, //!!!: cleanup
//                       imageSize: CGSize = CGSize.defaultAvatarSize,
//                       textColor: UIColor = UIColor.white,
//                       backgroundColor: UIColor = UIColor(hexString: "#c8c7cc")) -> UIImage? {
//        if let cachedImage = cachedIdentityImage(for: identity) {
//            // We have the image in cache. Return it.
//            return cachedImage
//        }
//
//        var image:UIImage?
//
//        let session = Session()
//        let safeIdentity = identity.safeForSession(session)
//        session.performAndWait { [weak self] in
//
//
//            guard let me = self else {
//                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
//                return
//            }
//
//            if let addressBookID = safeIdentity.addressBookID {
//                // Get image from system AddressBook if any
//                let ab = AddressBook()
//                if let contact = ab.contactBy(addressBookID: addressBookID),
//                    let imgData = contact.thumbnailImageData {
//                    image = UIImage(data: imgData)
//                }
//            }
//
//            if image == nil {
//                // We cound not find an image anywhere. Let's create one with the initials
//                var initials = "?"
//                if let userName = safeIdentity.userName {
//                    initials = userName.initials()
//                } else {
//                    let namePart = safeIdentity.address.namePartOfEmail()
//                    initials = namePart.initials()
//                }
//                image =  me.identityImageFromName(initials: initials,
//                                              size: imageSize,
//                                              textColor: textColor,
//                                              imageBackgroundColor: backgroundColor)
//            }
//            if let safeImage = image {
//                // cache image
//                let saveKey = IdentityKey(identity: safeIdentity)
//                IdentityImageTool.imageCache[saveKey] = safeImage
//            }
//        }
//        return image
//    }

    func identityImage(for identityKey: IdentityKey,
                       imageSize: CGSize = CGSize.defaultAvatarSize,
                       textColor: UIColor = UIColor.white,
                       backgroundColor: UIColor = UIColor(hexString: "#c8c7cc")) -> UIImage? {
        if let cachedImage = cachedIdentityImage(for: identityKey) {
            // We have the image in cache. Return it.
            return cachedImage
        }

        var image:UIImage?

        if let addressBookID = identityKey.addressBookId {
            // Get image from system AddressBook if any
            if let contact = AddressBook.shared.contactBy(addressBookID: addressBookID),
                let imgData = contact.thumbnailImageData {
                image = UIImage(data: imgData)
            }
        }

        if image == nil {
            // We cound not find an image anywhere. Let's create one with the initials
            var initials = "?"
            if let userName = identityKey.userName {
                initials = userName.initials()
            } else {
                let namePart = identityKey.address.namePartOfEmail()
                initials = namePart.initials()
            }
            image =  identityImageFromName(initials: initials,
                                              size: imageSize,
                                              textColor: textColor,
                                              imageBackgroundColor: backgroundColor)
        }
        if let safeImage = image {
            // save image to cache
            IdentityImageTool.imageCache[identityKey] = safeImage
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
