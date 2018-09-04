//
//  ImapSyncOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

public class ImapSyncOperation: ConcurrentBaseOperation {
    let imapSyncData: ImapSyncData

    init(parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
                imapSyncData: ImapSyncData) {
        self.imapSyncData = imapSyncData
        super.init(parentName: parentName, errorContainer: errorContainer)
    }

    public func checkImapSync() -> Bool {
        if imapSyncData.sync == nil {
            addError(BackgroundError.ImapError.invalidConnection(info: comp))
            markAsFinished()
            return false
        }
        return true
    }

    public func addIMAPError(_ error: Error) {
        addError(error)
        imapSyncData.sync?.imapState.hasError = true
    }

    override func markAsFinished() {
        imapSyncData.sync?.delegate = nil
        super.markAsFinished()
    }

    override public func waitForBackgroundTasksToFinish() {
        imapSyncData.sync?.delegate = nil
        super.waitForBackgroundTasksToFinish()
    }
}

extension ImapSyncOperation: ImapSyncDelegateErrorHandlerProtocol {
    func handle(error: Error) {
        Log.shared.error(component: #function,
                         errorString: "\(error.localizedDescription)")
        addIMAPError(error)
        markAsFinished()
    }
}
