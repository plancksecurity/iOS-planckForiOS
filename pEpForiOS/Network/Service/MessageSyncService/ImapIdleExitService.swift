//
//  ImapIdleExitService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

class ImapIdleExitService: AtomicImapService {
    let imapSyncData: ImapSyncData
    var syncDelegate: DefaultImapSyncDelegate?
    var handler: ServiceFinishedHandler?

    init(parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil,
         imapSyncData: ImapSyncData) {
        self.imapSyncData = imapSyncData
        super.init(parentName: parentName, backgrounder: backgrounder)
        syncDelegate = ImapIdleExitServiceDelegate(errorHandler: self)
    }

    func handleFinishedOk() {
        handler?(nil)
    }
}

extension ImapIdleExitService: ServiceExecutionProtocol {
    func execute(handler: ServiceFinishedHandler?) {
        self.handler = handler
        imapSyncData.sync?.delegate = syncDelegate
        imapSyncData.sync?.exitIdle()
    }
}

extension ImapIdleExitService: ImapSyncDelegateErrorHandlerProtocol {
    func handle(error: Error) {
        addError(error)
        handler?(error)
    }
}

class ImapIdleExitServiceDelegate: DefaultImapSyncDelegate {
    override func idleFinished(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? ImapIdleExitService)?.handleFinishedOk()
    }
}
