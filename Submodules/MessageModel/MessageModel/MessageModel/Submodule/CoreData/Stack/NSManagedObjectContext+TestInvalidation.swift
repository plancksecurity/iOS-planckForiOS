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
    static let keyHasBeenReset = "isInvalid"

    /// Boolean property that's used in tests to flag a context as "not to be used anymore".
    ///
    /// Gets set to `true` on the main contexts when the DB gets reset.
    var hasBeenReset: Bool {
        get {
            var result = false
            performAndWait {
                guard let flag = userInfo.object(forKey: NSManagedObjectContext.keyHasBeenReset) as? NSNumber else {
                    result =  false
                    return
                }
                result = flag.boolValue
            }
            return result
        }
        set {
            performAndWait {
                let value = NSNumber(booleanLiteral: newValue)
                userInfo.setValue(value, forKey: NSManagedObjectContext.keyHasBeenReset)
            }
        }
    }
}
