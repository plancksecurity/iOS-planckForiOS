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
    /// - note: You are responsible that all tasks on backgroundQueue are finished
    ///         before returning from your execution block
    ///
    /// - Parameters:
    ///   - maxConcurrentOperationCount:    maxConcurrentOperationCount for the internal background
    ///                                     queue. If nil, the default of Operation is taken.
    ///   - qos:    qualityOfService of the internal background queue. If nil, the default of
    ///             Operation is taken.
    ///   - executionBlock: block of code to execute in the operation
    public init(maxConcurrentOperationCount: Int = 1,
                qos: QualityOfService? = nil,
                executionBlock: @escaping (_ operation: SelfReferencingOperation?) -> Void) {
        if let prio = qos {
            backgroundQueue.qualityOfService = prio
        }
        backgroundQueue.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.executionBlock = executionBlock
        super.init()
    }

    public override func cancel() {
        backgroundQueue.cancelAllOperations()
        super.cancel()
    }

    override public func main() {
        guard !isCancelled else {
            return
        }
        weak var weakSelf = self

        executionBlock(weakSelf)
        // Actually the client is reponsible to not return before all operations finished.
        // We make sure anyway.
        backgroundQueue.waitUntilAllOperationsAreFinished()
    }
}
