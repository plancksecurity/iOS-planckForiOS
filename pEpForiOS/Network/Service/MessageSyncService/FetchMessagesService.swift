//
//  FetchMessagesService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class FetchMessagesService: AtomicImapService {
    var fetchedMessageIDs = [MessageID]()

    func execute(imapSyncData: ImapSyncData, folderName: String = ImapSync.defaultImapInboxName,
                 handler: ((_ error: Error?) -> ())? = nil) {
        let loginOp = LoginImapOperation(
            parentName: parentName, errorContainer: self, imapSyncData: imapSyncData)
        let fetchOp = FetchMessagesOperation(
            parentName: parentName, errorContainer: self, imapSyncData: imapSyncData,
            folderName: folderName) { [weak self] message in
                // TODO
                if let mID = message.messageID {
                    self?.fetchedMessageIDs.append(mID)
                }
        }
        fetchOp.addDependency(loginOp)
        fetchOp.completionBlock = { [weak self] in
            handler?(self?.error)
        }
        backgroundQueue.addOperations([loginOp, fetchOp], waitUntilFinished: false)
    }
}
