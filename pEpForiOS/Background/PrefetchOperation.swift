//
//  PrefetchOperation.swift
//  pEp
//
//  Created by Borja González de Pablo on 02/08/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class PrefetchOperation: ConcurrentBaseOperation {

    let executionBlock: ()-> Void
    
    init (executionBlock: @escaping ()-> Void){
        self.executionBlock = executionBlock
        super.init()
    }


    override func main() {
        if(isCancelled){
            return
        }
        executionBlock()
    }

    
}
