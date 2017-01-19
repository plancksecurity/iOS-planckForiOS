//
//  ImapSyncOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

open class ImapSyncOperation: ConcurrentBaseOperation {
    var imapSync: ImapSync!
    let imapSyncData: ImapSyncData

    public init(parentName: String? = nil, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData) {
        self.imapSyncData = imapSyncData
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    public func checkImapSync() -> Bool {
        imapSync = imapSyncData.sync
        if imapSync == nil {
            addError(Constants.errorImapInvalidConnection(component: comp))
            markAsFinished()
            return false
        }
        return true
    }
}
