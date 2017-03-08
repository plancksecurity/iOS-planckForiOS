//
//  ImapSyncOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

open class ImapSyncOperation: ConcurrentBaseOperation {
    let imapSyncData: ImapSyncData

    public init(parentName: String? = nil, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData) {
        self.imapSyncData = imapSyncData
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    public func checkImapSync() -> Bool {
        if imapSyncData.sync == nil {
            addError(Constants.errorImapInvalidConnection(component: comp))
            markAsFinished()
            return false
        }
        return true
    }

    open func addIMAPError(_ error: NSError) {
        addError(error)
        imapSyncData.sync?.imapState.hasError = true
    }
}
