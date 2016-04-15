//
//  BaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class BaseOperation: NSOperation {

    let grandOperator: GrandOperator

    init(grandOperator: GrandOperator) {
        self.grandOperator = grandOperator
        super.init()
    }
}