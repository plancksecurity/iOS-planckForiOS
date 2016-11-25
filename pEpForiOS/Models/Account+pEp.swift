//
//  Account+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension Account {
    open func myself(queue: OperationQueue, block: ((_ identity: NSDictionary) -> Void)? = nil) {
        return PEPUtil.myself(account: self, queue: queue, block: block)
    }
}
