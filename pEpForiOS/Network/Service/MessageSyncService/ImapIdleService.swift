//
//  ImapIdleService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol ImapIdleServiceDelegate: class {
    func didEnterIdle(service: ImapIdleService)
}

class ImapIdleService: AtomicImapService {
    enum IdleResult {
        case nothing
        case error
        case newMessages
        case idleExit
    }

    weak var delegate: ImapIdleServiceDelegate?
    var idleResult: IdleResult = .nothing
    let imapSyncData: ImapSyncData

    var handler: ServiceFinishedHandler?
    var syncDelegate: DefaultImapSyncDelegate?

    init(parentName: String = #function, backgrounder: BackgroundTaskProtocol? = nil,
         imapSyncData: ImapSyncData) {
        self.imapSyncData = imapSyncData
        super.init(parentName: parentName, backgrounder: backgrounder)
        syncDelegate = ImapIdleSyncDelegate(errorHandler: self)
    }

    func handleNewMessages() {
        idleResult = .newMessages
        handler?(nil)
    }
}

extension ImapIdleService: ServiceExecutionProtocol {
    func cancel() {
        imapSyncData.sync?.delegate = nil
        self.handler = nil
    }

    func execute(handler: ServiceFinishedHandler?) {
        self.handler = handler
        imapSyncData.sync?.delegate = syncDelegate
        imapSyncData.sync?.sendIdle()
    }

    func didEnterIdle() {
        delegate?.didEnterIdle(service: self)
    }

    func didFinishIdle() {
        idleResult = .idleExit
        handler?(nil)
    }
}

extension ImapIdleService: ImapSyncDelegateErrorHandlerProtocol {
    func handle(error: Error) {
        addError(error)
        idleResult = .error
        handler?(error)
    }
}

class ImapIdleSyncDelegate: DefaultImapSyncDelegate {
    override func idleNewMessages(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? ImapIdleService)?.handleNewMessages()
    }

    override func messageChanged(_ sync: ImapSync, notification: Notification?) {
        // Will be called when the status of existing messages changes.
        // Can be ignored since the storing is already handled by PersistentImapFolder.
    }

    override func idleEntered(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? ImapIdleService)?.didEnterIdle()
    }

    override func idleFinished(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? ImapIdleService)?.didFinishIdle()
    }
}
