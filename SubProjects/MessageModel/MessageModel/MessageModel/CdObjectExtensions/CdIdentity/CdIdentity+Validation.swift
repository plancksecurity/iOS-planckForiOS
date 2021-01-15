//
//  CdIdentity+Validation.swift
//  MessageModel
//
//  Created by Andreas Buff on 21.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

extension CdIdentity {

    public override func validateForInsert() throws {
        // Every Identity MUST have a user_id!
        if userID == nil {
            userID = UUID().uuidString
        }
        try super.validateForInsert()
    }
}
