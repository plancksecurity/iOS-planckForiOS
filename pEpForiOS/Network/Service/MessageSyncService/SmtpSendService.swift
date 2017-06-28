//
//  SmtpSendService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class SmtpSendService {
    public var error: Error?

    private let backgroundQueue = OperationQueue()
    private let parentName: String?

    init(parentName: String? = nil) {
        self.parentName = parentName
    }

    func execute(
        smtpSendData: SmtpSendData,
        imapSyncData: ImapSyncData,
        handler: ((_ error: Error?) -> ())? = nil) {
        let context = Record.Context.background
        context.perform { [weak self] in
            if let _ = EncryptAndSendOperation.retrieveNextMessage(context: context) {
                self?.haveMailsToEncrypt(
                    smtpSendData: smtpSendData, imapSyncData: imapSyncData, handler: handler)
            } else {
                handler?(nil)
            }
        }
    }

    func haveMailsToEncrypt(smtpSendData: SmtpSendData,
                            imapSyncData: ImapSyncData,
                            handler: ((_ error: Error?) -> ())? = nil) {
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
            handler?(self?.error)
        }

        backgroundQueue.addOperations(
            [smtpLoginOp, sendOp, imapLoginOp, appendOp], waitUntilFinished: false)
    }
}

extension SmtpSendService: ServiceErrorProtocol {
    public func addError(_ error: Error) {
        if self.error == nil {
            self.error = error
        }
    }

    public func hasErrors() -> Bool {
        return error != nil
    }
}
