//
//  CdHeaderField+Clone.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension CdHeaderField {
    /**
     Clones this object.

     - Note: The (inverse) relationship message is not copied.
     */
    func clone(context: NSManagedObjectContext) -> CdHeaderField {
        let hf = CdHeaderField(context: context)

        hf.name = name
        hf.value = value

        return hf
    }
}
