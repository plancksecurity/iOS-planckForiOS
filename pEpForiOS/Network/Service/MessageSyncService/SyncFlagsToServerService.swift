//
//  SyncFlagsToServerService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

class SyncFlagsToServerService: AtomicImapService {
    let imapSyncData: ImapSyncData
    let folderName: String

    init(parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil,
         imapSyncData: ImapSyncData,
         folderName: String = ImapSync.defaultImapInboxName) {
        self.imapSyncData = imapSyncData
        self.folderName = folderName
        super.init(parentName: parentName, backgrounder: backgrounder)
    }

    func executeInternal(
        context: NSManagedObjectContext, taskID: BackgroundTaskID?,
        handler: ServiceFinishedHandler?) {
        do {
            let cdFolder = try imapSyncData.connectInfo.folderBy(name: folderName, context: context)
            let loginOp = LoginImapOperation(
                parentName: parentName, errorContainer: self, imapSyncData: imapSyncData)

            guard let syncOp = SyncFlagsToServerOperation(
                parentName: parentName, errorContainer: self, imapSyncData: imapSyncData,
                folder: cdFolder) else {
                    handle(error: OperationError.illegalParameter, taskID: taskID, handler: handler)
                    return
            }

            syncOp.addDependency(loginOp)
            syncOp.completionBlock = {  [weak self] in
                self?.backgrounder?.endBackgroundTask(taskID)
                handler?(self?.error)
            }

            backgroundQueue.addOperations([loginOp, syncOp], waitUntilFinished: false)
        } catch let err {
            handle(error: err, taskID: taskID, handler: handler)
        }
    }
}

extension SyncFlagsToServerService: ServiceExecutionProtocol {
    func execute(handler: ServiceFinishedHandler? = nil) {
        let bgID = backgrounder?.beginBackgroundTask(taskName: "SyncFlagsToServerService")
        let context = Record.Context.background
        context.perform { [weak self] in
            self?.executeInternal(context: context, taskID: bgID, handler: handler)
        }
    }
}
