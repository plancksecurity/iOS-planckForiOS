//
//  GrandOperatorOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 BaseOperation that uses GrandOperator.
 */
public class GrandOperatorOperation: BaseOperation {
    unowned var grandOperator: IGrandOperator

    public init(grandOperator: IGrandOperator) {
        self.grandOperator = grandOperator
        super.init()
    }
}
