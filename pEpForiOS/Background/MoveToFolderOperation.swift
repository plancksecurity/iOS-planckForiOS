//
//  MoveToFolderOperation.swift
//  pEp
//
//  Created by Andreas Buff on 10.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/// Moves all messages in the given folder to targetFolder if parent != tagetfolder.
class MoveToFolderOperation: ImapSyncOperation {

    var syncDelegate: MoveToFolderSyncDelegate?
    let folder: Folder

    init(parentName: String = #function, folder: Folder, imapSyncData: ImapSyncData,
         errorContainer: ServiceErrorProtocol = ErrorContainer()) {
        self.folder = folder
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    override public func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }
        syncDelegate = MoveToFolderSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate

        handleNextMessage()
    }

    func handleNextMessage() {
        //TODO:
        guard let nextMessage = retrieveNextMessage() else {
            markAsFinished()
            return
        }
    }

    func retrieveNextMessage() -> Message? {
        var result: Message? = nil
        privateMOC.performAndWait {[weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            //TODO: move to predicate factory
            let p = NSPredicate(format:
                "targetFolder != nil AND parent != targetFolder AND parent.account = %@",
                                imapSyncData.connectInfo.accountObjectID)
            let msg = CdMessage.first(predicate: p, in: me.privateMOC)
//            if let m = msg, let cdIdent = m.parent?.account?.identity {
//                result = (m.pEpMessageDict(), cdIdent.pEpIdentity(), m.objectID)
//            }
        }

        return result
    }
}

class MoveToFolderSyncDelegate: DefaultImapSyncDelegate {
    public override func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        //        (errorHandler as? AppendMailsOperationBase)?.handleNextMessage()
        //TODO:
    }

    public override func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
//        (errorHandler as? AppendMailsOperationBase)?.addIMAPError(ImapSyncError.folderAppendFailed)
//        (errorHandler as? AppendMailsOperationBase)?.markAsFinished()
        //TODO:
    }
    //TODO:
}

