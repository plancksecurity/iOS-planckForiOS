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

    public init(parentName: String, errorContainer: ServiceErrorProtocol = ErrorContainer(),
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

    open func addIMAPError(_ error: Error) {
        addError(error)
        imapSyncData.sync?.imapState.hasError = true
    }

    override func markAsFinished() {
        imapSyncData.sync?.delegate = nil
        super.markAsFinished()
    }

    override open func waitForFinished() {
        imapSyncData.sync?.delegate = nil
        super.waitForFinished()
    }
}

extension ImapSyncOperation: ImapSyncDelegateErrorHandlerProtocol {
    func handle(error: Error) {
        addIMAPError(error)
        markAsFinished()
    }
}
