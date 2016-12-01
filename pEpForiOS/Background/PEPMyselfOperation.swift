//
//  PEPMyselfOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

class PEPMyselfOperation: Operation {
    /**
     When the operation has run, this will be updated and contain the fingerprint
     (`kPepFingerprint`).
     */
    var identity = NSMutableDictionary()

    let account: Account

    init(account: Account) {
        self.account = account
    }

    override func main() {
        let session = PEPSession()
        let pEpId = PEPUtil.pEp(identity: account.user)
        identity = NSMutableDictionary(dictionary: pEpId)
        session.mySelf(identity)
    }
}
