//
//  Created by Borja González de Pablo on 02/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class SelfReferencingOperation: Operation {

    let executionBlock: (_ operation: SelfReferencingOperation?)-> Void

    init(executionBlock: @escaping (_ operation: SelfReferencingOperation?) -> Void) {
        self.executionBlock = executionBlock
        super.init()
    }

    override func main() {
        if (isCancelled){
            return
        }
        weak var weakSelf = self

        executionBlock(weakSelf)
    }
}
