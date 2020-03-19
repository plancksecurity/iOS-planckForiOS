//
//  PantomimeStore.swift
//  MessageModel
//
//  Created by Andreas Buff on 22.11.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import PantomimeFramework
import CoreData

class PantomimeStore: CWIMAPStore {
    let connectInfo: EmailConnectInfo

    init(connectInfo: EmailConnectInfo) {
        self.connectInfo = connectInfo
        super.init(name: connectInfo.networkAddress,
                   port: UInt32(connectInfo.networkPort),
                   transport: connectInfo.connectionTransport,
                   clientCertificate: connectInfo.clientCertificate)
    }

    override func folder(withName name: String) -> CWIMAPFolder? {
        return PersistentImapFolder(name: name,
                                    accountID: connectInfo.accountObjectID)
    }
}
