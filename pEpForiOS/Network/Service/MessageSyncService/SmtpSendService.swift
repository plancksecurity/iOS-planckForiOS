//
//  SmtpSendService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class SmtpSendService: AtomicImapService {
    /** On finish, the messageIDs of the messages that have been sent successfully */
    private(set) public var successfullySentMessageIDs = [String]()

    func execute(
        smtpSendData: SmtpSendData,
        imapSyncData: ImapSyncData,
        handler: ServiceFinishedHandler? = nil) {
        let bgID = backgrounder?.beginBackgroundTask(taskName: "SmtpSendService")
        let context = Record.Context.background
        context.perform { [weak self] in
            guard let cdAccount = context.object(with: smtpSendData.connectInfo.accountObjectID)
                as? CdAccount else {
                    handler?(CoreDataError.couldNotFindAccount)
                    self?.backgrounder?.endBackgroundTask(bgID)
                    return
            }
            if let _ = EncryptAndSendOperation.retrieveNextMessage(
                context: context, cdAccount: cdAccount) {
                self?.haveMailsToEncrypt(
                    smtpSendData: smtpSendData, imapSyncData: imapSyncData,
                    bgID: bgID, handler: handler)
            } else {
                handler?(nil)
                self?.backgrounder?.endBackgroundTask(bgID)
            }
        }
    }

    func haveMailsToEncrypt(smtpSendData: SmtpSendData,
                            imapSyncData: ImapSyncData,
                            bgID: BackgroundTaskID?,
                            handler: ServiceFinishedHandler? = nil) {
        let smtpLoginOp = LoginSmtpOperation(
            parentName: parentName, smtpSendData: smtpSendData, errorContainer: self)
        let sendOp = EncryptAndSendOperation(
            parentName: parentName, smtpSendData: smtpSendData, errorContainer: self)
        sendOp.addDependency(smtpLoginOp)

        let imapLoginOp = LoginImapOperation(
            parentName: parentName, errorContainer: self, imapSyncData: imapSyncData)
        imapLoginOp.addDependency(sendOp)
        let appendOp = AppendMailsOperation(
            parentName: parentName, imapSyncData: imapSyncData, errorContainer: self)
        appendOp.addDependency(imapLoginOp)
        appendOp.completionBlock = { [weak self] in
            self?.successfullySentMessageIDs = appendOp.successfullySentMessageIDs
            handler?(self?.error)
            self?.backgrounder?.endBackgroundTask(bgID)
        }

        backgroundQueue.addOperations(
            [smtpLoginOp, sendOp, imapLoginOp, appendOp], waitUntilFinished: false)
    }
}
