//
//  BaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

/**
 Basic NSOperation that can gather errors.
 */
open class BaseOperation: Operation {
    open var errors: [NSError] = []

    open func addError(_ error: NSError) {
        errors.append(error)
    }

    open func hasErrors() -> Bool {
        return !errors.isEmpty
    }
}
