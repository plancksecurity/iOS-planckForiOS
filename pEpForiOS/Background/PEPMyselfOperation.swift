//
//  PEPMyselfOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class PEPMyselfOperation: NSOperation {
    /**
     When the operation has run, this will be updated and contain the fingerprint
     (`kPepFingerprint`).
     */
    let identity: NSMutableDictionary

    init(account: Account) {
        // It's important that we do this on the caller's thread,
        // b/c we access core data.
        identity = PEPUtil.identityFromAccount(account, isMyself: true)
    }

    override func main() {
        let session = PEPSession.init()
        session.mySelf(identity)
    }
}