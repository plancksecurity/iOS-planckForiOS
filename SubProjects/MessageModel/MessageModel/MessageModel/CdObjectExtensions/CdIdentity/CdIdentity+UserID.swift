//
//  CdIdentity+UserID.swift
//  MessageModel
//
//  Created by Andreas Buff on 16.07.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

extension CdIdentity {

    /// You MUST use this ID for all identities that you know belong to the user.
    /// This is also true for identities no acount exists for.
    static let pEpOwnUserID = "pEp_own_userId"

    // MARK: - MySelf

    var isMySelf: Bool {
        return userID == CdIdentity.pEpOwnUserID
    }
}
