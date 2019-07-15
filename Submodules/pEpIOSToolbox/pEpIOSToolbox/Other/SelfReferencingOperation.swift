//
//  Created by Borja González de Pablo on 02/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

public class SelfReferencingOperation: Operation {
    private let executionBlock: (_ operation: SelfReferencingOperation?)-> Void
    public let backgroundQueue = OperationQueue()

    public init(maxConcurrentOperationCount: Int? = nil,
                qos: QualityOfService = .background,
                executionBlock: @escaping (_ operation: SelfReferencingOperation?) -> Void) {
        backgroundQueue.qualityOfService = qos
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
