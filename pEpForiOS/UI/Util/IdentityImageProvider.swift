//
//  IdentityImageProvider.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

//BUFF: maybe obsolete
import MessageModel

typealias ImageReadyFunc = (UIImage, Identity) -> Void

protocol IdentityImageProviderProtocol {
    func image(forIdentity identity: Identity, callback: @escaping ImageReadyFunc)
}

class IdentityImageProvider: IdentityImageProviderProtocol {
    fileprivate let dispatchQueue = DispatchQueue(label: "IdentityImageProvider Queue")
    fileprivate let backgroundQueue = OperationQueue()
    fileprivate let identityImageCache = NSCache<Identity, UIImage>()

    /**
     Request an image.
     */
    open func image(forIdentity identity: Identity, callback: @escaping ImageReadyFunc) {
        dispatchQueue.async {
            self.internalImage(forIdentity: identity, callback: callback)
        }
    }

    fileprivate func internalImage(forIdentity identity: Identity,
                                   callback: @escaping ImageReadyFunc) {
        if let img = identityImageCache.object(forKey: identity) {
            callback(img, identity)
            return
        }
        let op = IdentityImageOperation(identity: identity,
                                        imageSize: CGSize.defaultAvatarSize,
                                        identityImageCache: identityImageCache)
        op.completionBlock = { [weak self, weak identity] in
            op.completionBlock = nil
            self?.dispatchQueue.async {
                if let theSelf = self, let theIdentity = identity, let img = op.image {
                    theSelf.finished(identity: theIdentity, image: img, callback: callback)
                }
            }
        }
        backgroundQueue.addOperation(op)
    }

    fileprivate func finished(identity: Identity, image: UIImage,
                              callback: @escaping ImageReadyFunc) {
        GCD.onMain {
            callback(image, identity)
        }
    }
}
