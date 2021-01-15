//
//  CdKey+Clone.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension CdKey {

    /// Clones this object.
    ///
    /// - Parameter context: context to clone on.
    /// - Returns: cloned object
    func clone(context: NSManagedObjectContext) -> CdKey {
        let clone = CdKey(context: context)
        clone.fingerprint = fingerprint
        return clone
    }
}
