//
//  Created by Borja González de Pablo on 02/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

//BUFF: move to toolbox
public class SelfReferencingOperation: Operation {

    private let executionBlock: (_ operation: SelfReferencingOperation?)-> Void

    public init(executionBlock: @escaping (_ operation: SelfReferencingOperation?) -> Void) {
        self.executionBlock = executionBlock
        super.init()
    }

    override public func main() {
        guard !isCancelled else {
            return
        }
        weak var weakSelf = self

        executionBlock(weakSelf)
    }
}
