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

open class DefaultMySelfer {
    let backgrounder: BackgroundTaskProtocol?
    let queue = LimitedOperationQueue()
    let parentName: String

    public init(parentName: String = #function, backgrounder: BackgroundTaskProtocol?) {
        self.parentName = parentName
        self.backgrounder = backgrounder
    }
}

extension DefaultMySelfer: KickOffMySelfProtocol {
    public func startMySelf() {
        let op = MySelfOperation(parentName: parentName, backgrounder: backgrounder)
        queue.addOperation(op)
    }
}
