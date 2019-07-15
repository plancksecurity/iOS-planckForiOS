//
//  Created by Borja González de Pablo on 02/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

public class SelfReferencingOperation: Operation {
    private let executionBlock: (_ operation: SelfReferencingOperation?)-> Void

    /// If you need to queue up opartions within the executionBlock, you MUST use this queue to
    /// assure canceling this SelfReferencingOperation also cancels internally queued up operations.
    public let backgroundQueue = OperationQueue()

    /// Creates an operation
    ///
    /// - Parameters:
    ///   - maxConcurrentOperationCount:    maxConcurrentOperationCount for the internal background
    ///                                     queue. If nil, the default of Operation is taken.
    ///   - qos:    qualityOfService of the internal background queue. If nil, the default of
    ///             Operation is taken.
    ///   - executionBlock: block of code to execute in the operation
    public init(maxConcurrentOperationCount: Int? = nil,
                qos: QualityOfService? = nil,
                executionBlock: @escaping (_ operation: SelfReferencingOperation?) -> Void) {
        if let prio = qos {
            backgroundQueue.qualityOfService = prio
        }
        if let maxConcurrentTasks = maxConcurrentOperationCount {
            backgroundQueue.maxConcurrentOperationCount = maxConcurrentTasks
        }
        self.executionBlock = executionBlock
        super.init()
    }

    public override func cancel() {
        backgroundQueue.cancelAllOperations()
        backgroundQueue.waitUntilAllOperationsAreFinished()
        super.cancel()
    }

    override public func main() {
        guard !isCancelled else {
            return
        }
        weak var weakSelf = self

        executionBlock(weakSelf)
    }
}
