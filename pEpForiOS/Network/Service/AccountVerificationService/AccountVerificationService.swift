//
//  AccountVerificationService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

class AccountVerificationService: AccountVerificationServiceProtocol {
    weak var delegate: AccountVerificationServiceDelegate?
    var accountVerificationState = AccountVerificationState.idle

    var runningOperations = [Account:[BaseOperation]]()
    let verificationQueue = DispatchQueue(
        label: "AccountVerificationService.verificationQueue", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()

    func verify(account: Account) {
        verificationQueue.async {
            self.verifyInternal(account: account)
        }
    }

    func removeFromRunning(account: Account) {
        verificationQueue.async {
            self.removeFromRunningInternal(account: account)
        }
    }

    func removeFromRunningInternal(account: Account) {
        guard let ops = runningOperations[account] else {
            return
        }
        let runningOps = ops.filter() {
            return !$0.isFinished
        }
        if runningOps.isEmpty {
            runningOperations[account] = nil
            let errorOps = ops.filter() { return $0.hasErrors() }
            if let op = errorOps.first, let err = op.error {
                if let imapErr = err as? ImapSyncError {
                    delegate?.verified(account: account, service: self,
                                       result: .imapError(imapErr))
                } else if let smtpErr = err as? SmtpSendError {
                    delegate?.verified(account: account, service: self,
                                       result: .smtpError(smtpErr))
                }
            } else {
                account.needsVerification = false
                delegate?.verified(account: account, service: self, result: .ok)
            }
        }
    }

    func verifyInternal(account: Account) {
        if runningOperations[account] != nil {
            return
        }
        let cdAccount = CdAccount.create(account: account)
        guard let imapConnectInfo = cdAccount.imapConnectInfo else {
            delegate?.verified(account: account, service: self, result: .noImapConnectData)
            return
        }
        guard let smtpConnectInfo = cdAccount.smtpConnectInfo else {
            delegate?.verified(account: account, service: self, result: .noSmtpConnectData)
            return
        }
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let smtpSendData = SmtpSendData(connectInfo: smtpConnectInfo)
        let imapVerifyOp = LoginImapOperation(
            parentName: #function, errorContainer: ErrorContainer(), imapSyncData: imapSyncData)
        imapVerifyOp.completionBlock = {[weak self] in
            self?.removeFromRunning(account: account)
        }
        let smtpVerifyOp = LoginSmtpOperation(
            parentName: #function, smtpSendData: smtpSendData, errorContainer: ErrorContainer())
        smtpVerifyOp.completionBlock = {[weak self] in
            self?.removeFromRunning(account: account)
        }
        runningOperations[account] = [imapVerifyOp, smtpVerifyOp]
        backgroundQueue.addOperation(imapVerifyOp)
        backgroundQueue.addOperation(smtpVerifyOp)
    }
}
