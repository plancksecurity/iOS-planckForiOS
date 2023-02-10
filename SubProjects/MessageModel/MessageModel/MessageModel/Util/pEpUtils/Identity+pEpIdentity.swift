//
//  Identity+pEpIdentity.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PEPObjCAdapter

extension Identity {
    func pEpIdentity() -> PEPIdentity {
        return cdObject.pEpIdentity()
    }

    static func from(pEpIdentity: PEPIdentity, context: NSManagedObjectContext) -> Identity? {
        guard let cdIdentity = CdIdentity.from(pEpContact: pEpIdentity, context: context) else {
            return nil
        }
        return Identity(cdObject: cdIdentity, context: context)
    }
}
