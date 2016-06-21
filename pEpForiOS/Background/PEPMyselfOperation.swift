//
//  PEPMyselfOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

class PEPMyselfOperation: NSOperation {
    let identity: NSMutableDictionary

    init(account: Account) {
        identity = PEPUtil.identityFromAccount(account, isMyself: true)
    }

    override func main() {
        let session = PEPSession.init()
        session.mySelf(identity)
    }
}
