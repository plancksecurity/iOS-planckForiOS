//
//  NSManagedObjectContext+TestInvalidation.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.10.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    static let keyIsInvalid = "isInvalid"

    /// Boolean property that's used in tests to flag a context as "not to be used anymore".
    ///
    /// Gets set to `true` on the main contexts when the DB gets reset.
    var isInvalid: Bool {
        get {
            guard let flag = userInfo.object(forKey: NSManagedObjectContext.keyIsInvalid) as? NSNumber else {
                return false
            }
            return flag.boolValue
        }
        set {
            userInfo.setValue(NSNumber(booleanLiteral: newValue),
                              forKey: NSManagedObjectContext.keyIsInvalid)
        }
    }
}
