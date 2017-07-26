//
//  FetchMessagesService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol FetchMessagesServiceDelegate: class {
    func didFetch(message: Message)
}

class FetchMessagesService: AtomicImapService {
    weak var delegate: FetchMessagesServiceDelegate?

    let imapSyncData: ImapSyncData
    let folderName: String

    init(parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil,
                  imapSyncData: ImapSyncData,
                  folderName: String = ImapSync.defaultImapInboxName) {
        self.imapSyncData = imapSyncData
        self.folderName = folderName
        super.init(parentName: parentName, backgrounder: backgrounder)
    }
}

extension FetchMessagesService: ServiceExecutionProtocol {
    func execute(handler: ServiceFinishedHandler? = nil) {
        let bgID = backgrounder?.beginBackgroundTask(taskName: "FetchMessagesService")
        let loginOp = LoginImapOperation(
            parentName: parentName, errorContainer: self, imapSyncData: imapSyncData)
        let fetchOp = FetchMessagesOperation(
            parentName: parentName, errorContainer: self, imapSyncData: imapSyncData,
            folderName: folderName) { [weak self] cdMessage in
                if let del = self?.delegate, let msg = cdMessage.message() {
                    del.didFetch(message: msg)
                }
        }
        fetchOp.addDependency(loginOp)
        fetchOp.completionBlock = { [weak self] in
            fetchOp.completionBlock = nil
            self?.backgrounder?.endBackgroundTask(bgID)
            handler?(self?.error)
        }
        backgroundQueue.addOperations([loginOp, fetchOp], waitUntilFinished: false)
    }
}
