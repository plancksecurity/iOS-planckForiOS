//
//  DelayOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 19.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class DelayOperation: ConcurrentBaseOperation {
    private let managementQueue = DispatchQueue(
        label: "InboxSync.managementQueue", qos: .utility, target: nil)
    let delayInSeconds: Double

    init(delayMilliseconds: Double) {
        self.delayInSeconds = delayMilliseconds
    }

    override func main() {
        managementQueue.asyncAfter(
        deadline: DispatchTime.now() + delayInSeconds) {
            self.markAsFinished()
        }
    }
}
