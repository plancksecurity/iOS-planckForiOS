//
//  ConnectInfo.swift
//  pEp
//
//  Created by Andreas Buff on 23.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

class ConnectInfo: Hashable {
    let account: AccountInfoCache

    var accountObjectID: NSManagedObjectID {
        return account.objectID
    }

    private let credentials: ServerCredentialsInfoCache

    let loginName: String?
    let networkAddress: String
    let networkPort: UInt16

    var loginPassword: String? {
        return credentials.password
    }

    var clientCertificate: SecIdentity? {
        return credentials.clientCertificate
    }

    init(account: CdAccount,
         server: CdServer,
         credentials: CdServerCredentials,
         loginName: String? = nil,
         networkAddress: String,
         networkPort: UInt16) {
        self.account = AccountInfoCache(cdAccount: account)
        self.credentials = ServerCredentialsInfoCache(cdServerCredentials: credentials)
        self.loginName = loginName
        self.networkAddress = networkAddress
        self.networkPort = networkPort
    }

    // MARK: Hashable/Equatable

    static func ==(l: ConnectInfo, r: ConnectInfo) -> Bool {
        return l.account == r.account  && l.credentials == r.credentials
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(account)
        hasher.combine(credentials)
    }
}
