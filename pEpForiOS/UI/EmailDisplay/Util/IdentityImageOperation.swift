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
}
