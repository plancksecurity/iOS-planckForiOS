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
        label: "DelayOperation.managementQueue", qos: .utility, target: nil)
    let delayInSeconds: Double

    init(parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
         delayInSeconds: Double) {
        self.delayInSeconds = delayInSeconds
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    override func main() {
        managementQueue.asyncAfter(
        deadline: DispatchTime.now() + delayInSeconds) {
            self.markAsFinished()
        }
    }

    override func cancel() {
        self.markAsFinished()
    }
}
