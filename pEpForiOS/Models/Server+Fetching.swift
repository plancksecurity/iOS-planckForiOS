//
//  Server+Fetching.swift
//  pEp
//
//  Created by Andreas Buff on 18.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpUtilities

extension Server {

    public struct Fetch {
        static public func allAccountsAllowedToManuallyTrust() -> [Account] {
            let p = CdServer.PredicateFactory.isAllowedToManuallyTrust()
            let cdServers: [CdServer] = CdServer.all(predicate: p) as? [CdServer] ?? []
            var accounts = [Account]()
            for cdServer in cdServers {
                guard let account = cdServer.account?.account() else {
                    Logger.modelLogger.errorAndCrash("No address")
                    continue
                }
                accounts.append(account)
            }
            return accounts
        }
    }
}
