//
//  BaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class BaseOperation: NSOperation {

    let grandOperator: IGrandOperator

    public init(grandOperator: IGrandOperator) {
        self.grandOperator = grandOperator
        super.init()
    }
}