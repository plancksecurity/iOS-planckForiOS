//
//  AppendDraftMailsOperation.swift
//  MessageModel
//
//  Created by Andreas Buff on 12.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

import PantomimeFramework
import PEPObjCAdapterFramework

/// Operation for storing mails in any type of IMAP folder.
class AppendMailsToFolderOperation: ImapSyncOperation {
    enum EncryptMode {
        case forSelf
        case unencryptedForTrustedServer
    }

    private var encryptMode: EncryptMode {
        let isTrusted = imapConnection.isTrusted(context: privateMOC)
        return isTrusted ? .unencryptedForTrustedServer : .forSelf
    }

    /** The object ID of the last handled message, so we can modify/delete it on success */
    private var lastHandledMessageObjectID: NSManagedObjectID?

    private let folderCache: FolderInfoCache

    init(parentName: String = #function,
         folder: CdFolder,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol) {
        folderCache = FolderInfoCache(cdFolder: folder)
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
    }

    override public func main() {
        if !checkImapSync() {
            waitForBackgroundTasksAndFinish()
            return
        }
        syncDelegate = AppendMailsToFolderSyncDelegate(errorHandler: self)
        imapConnection.delegate = syncDelegate

        handleNextMessage()
    }
}

// MARK: - Private

extension AppendMailsToFolderOperation {

    private func handleNextMessage() {//!!!: IOS-2325_!
        backgroundQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.privateMOC.performAndWait {
                me.markLastMessageAsFinished()
                guard !me.isCancelled else {
                    me.privateMOC.saveAndLogErrors()
                    me.waitForBackgroundTasksAndFinish()
                    return
                }
                guard let (cdMessage, pEpidentity) = me.retrieveNextMessage() else {
                    me.waitForBackgroundTasksAndFinish()
                    return
                }
                me.lastHandledMessageObjectID = cdMessage.objectID
                let messageIsAlreadyEncryptedForExtraKeys = cdMessage.isReEncryptedWithExtraKeys
                let pEpMessage = cdMessage.pEpMessage()

                let shouldNotAppend =
                    // We are not supposed to append messages to this folder. E.g. to Gmail sent folder.
                    me.folderCache.shouldNotAppendMessages &&
                        // We _do_ want to append mails the Engine told us to reUpload though
                        !messageIsAlreadyEncryptedForExtraKeys &&
                        // We _do_ want to append unencrypted version for trustedServers
                        me.encryptMode != .unencryptedForTrustedServer
                if shouldNotAppend {
                    // We are not supposed to append. Ignore this message. //!!!: should we delete it? I think so! Its a message marked for appending in a folder we should not append to. Imo it causes ending in this if clause on every replication loop for every affected message.
                    me.handleNextMessage()
                    return
                }
                let pepRating = PEPRating(rawValue: Int32(cdMessage.pEpRating))
                if (!cdMessage.pEpProtected || pepRating == .unencrypted) && me.folderCache.folderType == .sent {
                    // Do not encrypt messages that the user has sent force-unprotected when
                    // appending it to "Sent" folder.
                    me.appendMessage(pEpMessage: pEpMessage)
                    return
                }

                // Even the policy should be "pass every message to the Engine, no matter what",
                // there are exceptions where we were told to not do it (crashes the Engine or
                // returns PEP_ILLEGAL_VALUE).
                let appendWithoutBotheringTheEngine =
                    me.encryptMode == .unencryptedForTrustedServer || // Always append unencrypted and without bothering the Engine for trusted server ...
                        messageIsAlreadyEncryptedForExtraKeys || // The message is reencrypted for extra keys, must not be encrypted again. Do not show to the Engine neither.
                        cdMessage.isAutoConsumable // Engine asked to append this

                guard !appendWithoutBotheringTheEngine else {
                    me.appendMessage(pEpMessage: pEpMessage)
                    return
                }

                do {
                    let forceUnprotected = !cdMessage.pEpProtected
                    let extraKeysFPRs = CdExtraKey.fprsOfAllExtraKeys(in: me.privateMOC)
                    let encryptedMessage = try PEPUtils.encrypt(pEpMessage: pEpMessage,//!!!: IOS-2325_!
                                                                encryptionFormat: forceUnprotected ? .none : .PEP,
                                                                forSelf: forceUnprotected ? nil : pEpidentity,
                                                                extraKeys: extraKeysFPRs)
                    me.appendMessage(pEpMessage: encryptedMessage)
                } catch let error as NSError {
                    if error.domain == PEPObjCAdapterEngineStatusErrorDomain {
                        switch error.code {
                        case Int(PEPStatus.passphraseRequired.rawValue):
                            //BUFF: keep unhandled and see how it works with the adapters new delegate approach
                            break
//                            me.handleError(BackgroundError.PepError.passphraseRequired(info:"Passphrase required encrypting message: \(cdMessage)"))
                        case Int(PEPStatus.wrongPassphrase.rawValue):
                            //BUFF: keep unhandled and see how it works with the adapters new delegate approach
                            break
//                            me.handleError(BackgroundError.PepError.wrongPassphrase(info:"Passphrase wrong encrypting message: \(cdMessage)"))
                        default:
                            Log.shared.errorAndCrash("Error decrypting: %@", "\(error)")
                            me.handleError(BackgroundError.GeneralError.illegalState(info:
                                "##\nError: \(error)\nencrypting message: \(cdMessage)\n##"))
                        }
                    } else if error.domain == PEPObjCAdapterErrorDomain {
                        Log.shared.errorAndCrash("Unexpected ")
                        me.handleError(BackgroundError.GeneralError.illegalState(info:
                            "We do not exept this error domain to show up here: \(error)"))
                    } else {
                        Log.shared.errorAndCrash("Unhandled error domain: %@", "\(error.domain)")
                        me.handleError(BackgroundError.GeneralError.illegalState(info:
                            "Unhandled error domain: \(error.domain)"))
                    }
                }
            }
        }
    }

    private func retrieveNextMessage() -> (CdMessage, PEPIdentity)? {
        guard
            let account = imapConnection.cdAccount(moc: privateMOC),
            let address = account.identity?.address
            else {
                Log.shared.errorAndCrash("Missing data")
                return nil
        }
        let p = CdMessage.PredicateFactory.needImapAppend(inFolderNamed: folderCache.name,
                                                          inAccountWithAddress: address)
        guard
            let cdMessage = CdMessage.first(predicate: p, in: privateMOC),
            let cdIdent = cdMessage.parent?.account?.identity else {
                return nil
        }
        return (cdMsg: cdMessage, pEpIdentity: cdIdent.pEpIdentity())
    }

    private func markLastMessageAsFinished() {
        guard let msgID = lastHandledMessageObjectID else {
            return
        }
        if let obj = privateMOC.object(with: msgID) as? CdMessage {
            privateMOC.delete(obj)
            privateMOC.saveAndLogErrors()
        } else {
            Log.shared.errorAndCrash("Message disappeared")
            handleError(BackgroundError.GeneralError.invalidParameter(info: #function),
                        message: "Cannot find message just stored.")
            return
        }
    }

    private func appendMessage(pEpMessage msg: PEPMessage) {
        let pantMail = PEPUtils.pantomime(pEpMessage: msg)
        guard let rawData = pantMail.dataValue() else {
            Log.shared.errorAndCrash("No data")
            waitForBackgroundTasksAndFinish()
            return
        }
        imapConnection.append(messageData: rawData,
                              folderType: folderCache.folderType,
                              folderName: folderCache.name,
                              internalDate: imapAppendInternalDate(forMessageToAppend: msg),
                              context: privateMOC)
    }

    /// When reuploading an unencrypted  mesage for trusted server the date must be the date sent to not change the order in webmail.
    private func imapAppendInternalDate(forMessageToAppend msg: PEPMessage) -> Date? {
        return encryptMode == .unencryptedForTrustedServer ? msg.sentDate : nil
    }
}

// MARK: - Extra Keys

extension CdMessage {
    fileprivate var isReEncryptedWithExtraKeys: Bool {
        guard let flags = PEPDecryptFlags(rawValue: flagsFromDecryptionRawValue) else {
            // No flag set.
            return false
        }
        return flags.flagIsSet(flag: .sourceModified)
    }
}

// MARK: - Callback Handler

extension AppendMailsToFolderOperation {

    fileprivate func handleFolderAppendCompleted() {
        handleNextMessage()
    }

    fileprivate func handleFolderAppendFailed() {
        handle(error: ImapSyncOperationError.folderAppendFailed)
    }
}

class AppendMailsToFolderSyncDelegate: DefaultImapConnectionDelegate {
    public override func folderAppendCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? AppendMailsToFolderOperation) else {
            Log.shared.errorAndCrash("No OP")
            return
        }
        op.handleFolderAppendCompleted()
    }

    public override func folderAppendFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? AppendMailsToFolderOperation) else {
            Log.shared.errorAndCrash("No OP")
            return
        }
        op.handleFolderAppendFailed()
    }
}
