//
//  SmtpSendService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol SmtpSendServiceDelegate: class {
    func sent(messageIDs: [MessageID])
}

class SmtpSendService: BackgroundOperationImapService {
    weak var delegate: SmtpSendServiceDelegate?

    let smtpSendData: SmtpSendData

    init(parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil,
         imapSyncData: ImapSyncData, smtpSendData: SmtpSendData) {
        self.smtpSendData = smtpSendData
        super.init(parentName: parentName, backgrounder: backgrounder, imapSyncData: imapSyncData)
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
            appendOp.completionBlock = nil
            self?.executingOperations.removeAll()
            self?.delegate?.sent(messageIDs: appendOp.successfullySentMessageIDs)
            handler?(self?.error)
            self?.backgrounder?.endBackgroundTask(bgID)
        }

        executingOperations.append(contentsOf: [smtpLoginOp, sendOp, imapLoginOp, appendOp])
        backgroundQueue.addOperations(
            executingOperations, waitUntilFinished: false)
    }

    override func cancel() {
        super.cancel()
        smtpSendData.smtp?.delegate = nil
    }
}

extension SmtpSendService: ServiceExecutionProtocol {
    func execute(handler: ServiceFinishedHandler? = nil) {
        let bgID = backgrounder?.beginBackgroundTask(taskName: "SmtpSendService")
        let context = Record.Context.background
        context.perform { [weak self] in
            guard
                let imapSyncData = self?.imapSyncData,
                let smtpSendData = self?.smtpSendData else {
                    self?.handle(
                        error: OperationError.illegalParameter, taskID: bgID, handler: handler)
                    return
            }

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
}
