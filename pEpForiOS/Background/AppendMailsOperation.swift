//
//  AppendDraftMailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

/// Operation for storing mails in any type of IMAP folder.
public class AppendMailsOperation: ImapSyncOperation {
    enum EncryptMode {
        case forSelf
        case unencryptedForTrustedServer
    }
    private var encryptMode: EncryptMode {
        return imapSyncData.connectInfo.trusted ? .unencryptedForTrustedServer : .forSelf
    }
    private var syncDelegate: AppendMailsSyncDelegate?

    /** The object ID of the last handled message, so we can modify/delete it on success */
    var lastHandledMessageObjectID: NSManagedObjectID?

    private let folder: Folder

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
        syncDelegate = AppendMailsSyncDelegate(errorHandler: self)
        imapSyncData.sync?.delegate = syncDelegate

        handleNextMessage()
    }

    func retrieveNextMessage() -> (PEPMessageDict, PEPIdentity, NSManagedObjectID)? {
        var result: (PEPMessageDict, PEPIdentity, NSManagedObjectID)? = nil
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            guard
                let accountId = imapSyncData.connectInfo.accountObjectID,
                let account = privateMOC.object(with: accountId) as? CdAccount,
                let address = account.identity?.address
                else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Missing data")
                    result = nil
                    return
            }
            let p = CdMessage.PredicateFactory.needImapAppend(inFolderNamed: me.folder.name,
                                                              inAccountWithAddress: address)
            let msg = CdMessage.first(predicate: p, in: me.privateMOC)
            if let m = msg, let cdIdent = m.parent?.account?.identity {
                result = (m.pEpMessageDict(), cdIdent.pEpIdentity(), m.objectID)
            }
        }
        return result
    }

    func markLastMessageAsFinished() {
        if let msgID = lastHandledMessageObjectID {
            privateMOC.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash(component: #function, errorString: "I got lost")
                    return
                }
                if let obj = me.privateMOC.object(with: msgID) as? CdMessage {
                    me.privateMOC.delete(obj)
                    me.privateMOC.saveAndLogErrors()
                } else {
                    Log.shared.errorAndCrash(component: #function,
                                             errorString: "Message dissapeared")
                    me.handleError(BackgroundError.GeneralError.invalidParameter(info: #function),
                                   message: "Cannot find message just stored.")
                    return
                }
            }
        }
    }

    private func appendMessage(pEpMessageDict msg: PEPMessageDict) {
        let pantMail = PEPUtil.pantomime(pEpMessageDict: msg)
        let cwFolder = CWIMAPFolder(name: folder.name)
        if let sync = imapSyncData.sync {
            cwFolder.setStore(sync.imapStore)
        }
        guard let rawData = pantMail.dataValue() else {
            Log.shared.errorAndCrash(component: #function, errorString: "No data")
            markAsFinished()
            return
        }
        let flags = self.folder.folderType.defaultAppendImapFlags()
        cwFolder.appendMessage(fromRawSource: rawData,
                               flags: flags?.pantomimeFlags(),
                               internalDate: nil)
    }

    private func encrypt(session: PEPSession, pEpMessageDict: PEPMessageDict, forSelf: PEPIdentity? = nil)
        throws -> (PEP_STATUS, NSDictionary?) {
            return try session.encrypt(pEpMessageDict: pEpMessageDict, forSelf: forSelf)
    }

    fileprivate func handleNextMessage() {
        markLastMessageAsFinished()
        guard !isCancelled else {
            waitForBackgroundTasksToFinish()
            return
        }
        guard let (msg, ident, objID) = retrieveNextMessage() else {
            markAsFinished()
            return
        }
        lastHandledMessageObjectID = objID
        let uuidBeforeEngine = msg["id"]

        if folder.shouldNotAppendMessages {
            // We are not supposed to append messages to this forder.
            // We need to handle all messages anyway to make sure markLastMessageAsFinished() is
            // called on them (i.e. they get delted).
            handleNextMessage()
            return
        }

        if encryptMode == .unencryptedForTrustedServer {
            // Always append unencrypted for trusted server.
            appendMessage(pEpMessageDict: msg)
        } else if encryptMode == .forSelf {
            do {
                let session = PEPSession()
                let (_, encMsg) = try encrypt(session: session, pEpMessageDict: msg, forSelf: ident)
                guard var msgDict = encMsg as? PEPMessageDict else {
                    Log.shared.errorAndCrash(component: #function, errorString: "Error casting")
                    handleError(BackgroundError.GeneralError.illegalState(info: "Eror casting"),
                                message: "Error casting")
                    return
                }
                msgDict["id"] = uuidBeforeEngine //IOS-647 ask if this is OK. If not, do vise versa (save new uuid from engine to all msgs in CD with old uuid)
                // ...  and append.
                appendMessage(pEpMessageDict: msgDict)
            } catch let err as NSError {
                handleError(err, message: "Cannot encrypt message")
            }
        }
    }

    override func markAsFinished() {
        syncDelegate = nil
        super.markAsFinished()
    }

    static func foldersContainingMarkedForAppend(connectInfo: EmailConnectInfo) -> [Folder] {
        var result = [Folder]()
        let privateMOC = Record.Context.background
        privateMOC.performAndWait {
            guard
                let accountId = connectInfo.accountObjectID,
                let cdAccount = privateMOC.object(with: accountId) as? CdAccount else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No account")
                    return
            }
            let appendMessages = Message.allMessagesMarkedForAppend(inAccount: cdAccount.account())
            let foldersContainingMessagesForAppend = appendMessages.map { $0.parent }
            result = Array(Set(foldersContainingMessagesForAppend))
        }

        return result
    }
}

class AppendMailsSyncDelegate: DefaultImapSyncDelegate {
    public override func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? AppendMailsOperation)?.handleNextMessage()
    }

    public override func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? AppendMailsOperation)?.addIMAPError(ImapSyncError.folderAppendFailed)
        (errorHandler as? AppendMailsOperation)?.markAsFinished()
    }
}
