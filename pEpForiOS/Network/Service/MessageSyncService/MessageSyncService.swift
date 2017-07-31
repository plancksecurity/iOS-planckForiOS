//
//  MessageSyncService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

/**
 ## IMAP sync operations
 
 There are the following kind of IMAP syncs that should not run concurrent, but be serialized:
 
 - *Standard IMAP sync*, which seems to be the same as the *initial sync*:
   - *Bail out* immediately if there is already that kind of sync running for that particual server.
   - If there are other IMAP operations running for that server, wait for them to finish.
   - Otherwise, just start:
     - Fetch *important folders*, that is:
       - Top level
       - The level below INBOX
     - Fetch newest Mails from INBOX
 
 - IMAP operations for the same server, that are not directly sync related:
   - Delete/Append operations as consequence of *moving a message*.
     Since that changes the contents of folders, this should rightly block message fetch.
     An append operation should entail a subsequent fetch operation for that particular folder.
     A delete operations should be followed by a 'sync existing messages' operations.
   - *Flag change* operations. Also should block email fetch, and should entail the syncing
     of existing messages.
   - Append operations as a consequence of a *send message action* (see SMTP section).
     Should entail the fetch of new messages for that particular folder.

 Those can be synced by a wrapper around an operation queue, that also tracks
 the *kind* of operations that are currently being executed.
 
 Every unique IMAP server/login combination has its own queue object.
 
 ## How to handle SMTP operations
 
 In theory, they are independent of IMAP, and should not block the fetching of new emails.
 In practice, every SMTP operation will be followed by some IMAP operations, like
 append (to the sent folder). So an SMTP queue must have a reference to the corresponding
 IMAP queue in order to request the pending IMAP actions.
 
 ## User initiated actions
 
 IDLE could mean the IMAP command, or polling periodically. The described actions
 have to be executed for each account, or the account that is concerned.
 
 This means that for every account, and certain folders, a state machine has to be executed.
 
 - App start
   IMAP: fetch important folders, fetch new messages (INBOX), sync existing ones (INBOX),
   IDLE (INBOX).
 - Send emails
   First SMTP, then IMAP: fetch new messages (sent folder), IDLE (INBOX).
 - Visit a folder
   IMAP: fetch new messages (folder), sync existing ones (folder), IDLE (folder).
 - Add new account
   Basically the same as for 'App start'.

 The fetching of important folders should happen periodically.
 The fetching of new messages, and syncing of existing messages, for the INBOX,
 and a currently visited folder, should happen periodically.
 The INBOX should be handled by IDLE.
 */
class MessageSyncService: MessageSyncServiceProtocol {
    public enum InternalError: Error {
        case noAccount
        case noConnectInfos
    }

    weak var errorDelegate: MessageSyncServiceErrorDelegate?
    weak var sentDelegate: MessageSyncServiceSentDelegate?
    weak var syncDelegate: MessageSyncServiceSyncDelegate?
    weak var stateDelegate: MessageSyncServiceStateDelegate?
    weak var flagsUploadDelegate: MessageSyncFlagsUploadDelegate?

    let sleepTimeInSeconds: Double
    let parentName: String
    let backgrounder: BackgroundTaskProtocol?
    let mySelfer: KickOffMySelfProtocol?
    let managementQueue = DispatchQueue(
        label: "MessageSyncService", qos: .utility, target: nil)

    private var imapConnections = [ImapSmtpConnection: ImapSmtpSyncService]()

    var accountVerifications = [Account:
        (AccountVerificationService, AccountVerificationServiceDelegate)]()

    init(sleepTimeInSeconds: Double = 10.0,
         parentName: String, backgrounder: BackgroundTaskProtocol? = nil,
         mySelfer: KickOffMySelfProtocol? = nil) {
        self.sleepTimeInSeconds = sleepTimeInSeconds
        self.parentName = parentName
        self.backgrounder = backgrounder
        self.mySelfer = mySelfer
    }

    func start(account: Account) {
        connectInfos(account: account) { [weak self] (ici, sci) in
            self?.managementQueue.async {
                self?.startInternal(imapConnectInfo: ici,
                                    smtpConnectInfo: sci)
            }
        }
    }

    func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
        managementQueue.async {
            self.requestVerificationInternal(account: account, delegate: delegate)
        }
    }

    func requestSend(message: Message) {
        connectInfos(account: message.parent?.account) { [weak self] (imapCI, smtpCI) in
            self?.managementQueue.async { [weak self] in
                self?.handleSendRequest(imapConnectInfo: imapCI,
                                        smtpConnectInfo: smtpCI, message: message)
            }
        }
    }

    func requestDraft(message: Message) {
        Log.shared.errorAndCrash(component: #function, errorString: "not implemented")
    }

    func requestMessageSync(folder: Folder) {
        Log.shared.errorAndCrash(component: #function, errorString: "not implemented")
    }

    func requestFlagChange(message: Message) {
        connectInfos(account: message.parent?.account) { [weak self] (imapCI, smtpCI) in
            self?.managementQueue.async { [weak self] in
                self?.handleFlagChange(imapConnectInfo: imapCI,
                                       smtpConnectInfo: smtpCI, message: message)
            }
        }
    }

    func cancel(account: Account) {
        connectInfos(account: account) { [weak self] (ici, sci) in
            self?.managementQueue.async {
                self?.cancelInternal(imapConnectInfo: ici,
                                     smtpConnectInfo: sci)
            }
        }
    }

    /**
     Cancel all accounts.
     */
    func cancel() {
        self.managementQueue.async {
            for (_, v) in self.imapConnections {
                v.cancel()
            }
        }
    }

    private func indicate(error: Error) {
        managementQueue.async { [weak self] in
            self?.errorDelegate?.show(error: error)
        }
    }

    private func lookUpOrCreateImapSmtpService(
        imapConnectInfo: EmailConnectInfo,
        smtpConnectInfo: EmailConnectInfo) -> ImapSmtpSyncService {
        let key = ImapSmtpConnection(
            imapConnectInfo: imapConnectInfo, smtpConnectInfo: smtpConnectInfo)
        let model = imapConnections[key] ??
            ImapSmtpSyncService(
                parentName: parentName,
                backgrounder: backgrounder,
                imapSyncData: ImapSyncData(connectInfo: imapConnectInfo),
                smtpSendData: SmtpSendData(connectInfo: smtpConnectInfo))
        model.delegate = self
        imapConnections[key] = model
        return model
    }

    private func startInternal(imapConnectInfo: EmailConnectInfo,
                               smtpConnectInfo: EmailConnectInfo) {
        lookUpOrCreateImapSmtpService(
            imapConnectInfo: imapConnectInfo, smtpConnectInfo: smtpConnectInfo).start()
    }
    
    private func cancelInternal(imapConnectInfo: EmailConnectInfo,
                                smtpConnectInfo: EmailConnectInfo) {
        lookUpOrCreateImapSmtpService(
            imapConnectInfo: imapConnectInfo, smtpConnectInfo: smtpConnectInfo).cancel()
    }

    private func requestVerificationInternal(account: Account,
                                             delegate: AccountVerificationServiceDelegate) {
        let service = AccountVerificationService()
        service.delegate = self
        accountVerifications[account] = (service, delegate)
        service.verify(account: account)
    }

    private func handleSendRequest(imapConnectInfo: EmailConnectInfo,
                           smtpConnectInfo: EmailConnectInfo, message: Message) {
        lookUpOrCreateImapSmtpService(
            imapConnectInfo: imapConnectInfo,
            smtpConnectInfo: smtpConnectInfo).enqueueForSending(message: message)
    }

    private func handleFlagChange(imapConnectInfo: EmailConnectInfo,
                                  smtpConnectInfo: EmailConnectInfo, message: Message) {
        lookUpOrCreateImapSmtpService(
            imapConnectInfo: imapConnectInfo,
            smtpConnectInfo: smtpConnectInfo).enqueueForFlagChange(message: message)
    }

    private func connectInfos(
        account: Account?,
        context: NSManagedObjectContext) -> (EmailConnectInfo, EmailConnectInfo)? {
        if let theAccount = account,
            let cdAccount = CdAccount.search(account: theAccount, context: context),
            let imapCI = cdAccount.imapConnectInfo, let smtpCI = cdAccount.smtpConnectInfo {
            return (imapCI, smtpCI)
        }
        return nil
    }

    private func connectInfos(account: Account?,
                              handler: @escaping (EmailConnectInfo, EmailConnectInfo) -> ()) {
        guard let theAccount = account else {
            indicate(error: InternalError.noAccount)
            return
        }
        let context = Record.Context.background
        context.perform { [weak self] in
            if let (iCI, sCI) = self?.connectInfos(account: theAccount, context: context) {
                handler((iCI, sCI))
            } else {
                self?.indicate(error: InternalError.noConnectInfos)
            }
        }
    }
}

extension MessageSyncService: AccountVerificationServiceDelegate {
    private func verifiedInternal(account: Account, service: AccountVerificationServiceProtocol,
                                  result: AccountVerificationResult) {
        guard let (service, delegate) = accountVerifications[account] else {
            Log.shared.errorComponent(#function, message: "no service")
            return
        }
        delegate.verified(account: account, service: service, result: result)
        accountVerifications[account] = nil
    }

    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        managementQueue.async {
            self.verifiedInternal(account: account, service: service, result: result)
        }
    }
}

extension MessageSyncService: ImapSmtpSyncServiceDelegate {
    func messagesSent(service: ImapSmtpSyncService, messages: [Message],
                      allMessageIDs: [MessageID]) {
        for msg in messages {
            sentDelegate?.didSend(message: msg)
        }
        sentDelegate?.didSend(messageIDs: allMessageIDs)
    }

    func handle(service: ImapSmtpSyncService, error: Error) {
        errorDelegate?.show(error: error)
    }

    func didSync(service: ImapSmtpSyncService) {
        if syncDelegate == nil {
            return
        }
        service.imapSyncData.connectInfo.handleAccount() { [weak self] account in
            self?.syncDelegate?.didSync(account: account)
        }
    }

    func startIdling(service: ImapSmtpSyncService) {
        if stateDelegate == nil {
            return
        }
        service.imapSyncData.connectInfo.handleAccount() { [weak self] account in
            self?.stateDelegate?.startIdling(account: account)
        }
    }

    func flagsUploaded(message: Message) {
        flagsUploadDelegate?.flagsUploaded(message: message)
    }
}
