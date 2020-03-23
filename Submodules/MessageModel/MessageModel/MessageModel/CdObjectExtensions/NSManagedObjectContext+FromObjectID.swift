//
//  NSManagedObjectContext+FromObjectID.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 27.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import pEpIOSToolbox

extension NSManagedObjectContext {
    /// Turns the given `NSManagedObjectID` into a valid `CdAccount`.
    /// - Returns: A valid CdAccount, or `nil` if the input ID is nil
    ///    or the found object is not a `CdAccount`.
    func cdAccount(from: NSManagedObjectID?) -> CdAccount? {
        guard let objId = from else {
            Log.shared.warn("Can't create CdAccount from object ID, given object ID is nil")
            return nil
        }
        let cdObj = object(with: objId)

        guard let cdAccount = cdObj as? CdAccount else {
            Log.shared.warn("Managed object '%@' is not a CdAccount", objId)
            return nil
        }

        return cdAccount
    }
}
