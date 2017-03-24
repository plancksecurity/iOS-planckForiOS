//
//  IdentityImageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

class IdentityImageOperation: Operation {
    let identity: Identity
    var image: UIImage?

    init(identity: Identity) {
        self.identity = identity
    }

    override func main() {
        var shouldCreateImage = true
        if let theID = identity.userID {
            let ab = AddressBook()
            if let contact = ab.contactBy(userID: theID),
                let imgData = contact.thumbnailImageData {
                shouldCreateImage = false
                image = UIImage(data: imgData)
            }
        }
        if shouldCreateImage {
            // background color: #c8c7cc
            // text color: #ffffff
        }
    }
}
