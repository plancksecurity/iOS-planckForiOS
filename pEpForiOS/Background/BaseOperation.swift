//
//  BaseOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 Basic NSOperation that can gather errors.
 */
public class BaseOperation: NSOperation {
    public var errors: [NSError] = []

    public func addError(error: NSError) {
        errors.append(error)
    }

    public func hasErrors() -> Bool {
        return !errors.isEmpty
    }
}