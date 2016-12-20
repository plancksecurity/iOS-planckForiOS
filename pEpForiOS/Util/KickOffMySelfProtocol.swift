//
//  KickOffMySelfProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public protocol KickOffMySelfProtocol {
    /**
     Should invoke mySelf on every `Identity` owned by the user.
     */
    func startMySelf()
}

open class DefaultMySelfer: KickOffMySelfProtocol {
    let backgrounder: BackgroundTaskProtocol?
    let queue = LimitedOperationQueue()

    public init(backgrounder: BackgroundTaskProtocol?) {
        self.backgrounder = backgrounder
    }

    public func startMySelf() {
        let op = MySelfOperation(backgrounder: backgrounder)
        queue.addOperation(op)
    }
}
