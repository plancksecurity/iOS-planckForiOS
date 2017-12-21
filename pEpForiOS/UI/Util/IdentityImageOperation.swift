//
//  IdentityImageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

//maybe obsolete
class IdentityImageOperation: Operation {
    /**
     The background color for the contact initials image.
     */
    let imageBackgroundColor = UIColor(hexString: "#c8c7cc")

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
        let imageTool = IdentityImageTool()
        image = imageTool.identityImage(for: identity, imageSize: imageSize, textColor: textColor,
                                        backgroundColor: imageBackgroundColor)
        if let img = image {
            identityImageCache.setObject(img, forKey: identity)
        }
    }
}
