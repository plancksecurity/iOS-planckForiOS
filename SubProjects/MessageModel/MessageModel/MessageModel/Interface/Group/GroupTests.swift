//
//  GroupTests.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 7/8/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation

import PlanckToolbox
import PEPObjCAdapter

public class GroupTests {
    static public func groupCreateAndInvite() {
        if let account = Account.all().first {
            if let deckard = Identity.by(address: "deckard@testnet.planck.dev") {
                let groupIdentity = PEPIdentity(address: "replicants@testnet.planck.dev",
                                                userID: "userID replicants@testnet.planck.dev",
                                                userName: "userName replicants@testnet.planck.dev",
                                                isOwn: false)
                let identity = account.user.pEpIdentity()
                let deckardIdentity = deckard.pEpIdentity()
                PEPSession().groupCreateGroupIdentity(groupIdentity, managerIdentity: identity, memberIdentities: [deckardIdentity]) { error in
                    Log.shared.log(error: error)
                } successCallback: { group in
                    Log.shared.logInfo(message: "Have created a group")
                }
            }
        }
    }
}
