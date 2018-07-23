//
//  SharedObjects.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 06/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

/**
 Used for building a line of operations for synching an account.
 */
public struct AccountConnectInfo {
    let needsVerification: Bool//IOS-1033: cleanup.
    let accountID: NSManagedObjectID//IOS-1033: cleanup.
    let imapConnectInfo: EmailConnectInfo?
    let smtpConnectInfo: EmailConnectInfo?
}

extension AccountConnectInfo {
    public init(accountID: NSManagedObjectID) {
        self.needsVerification = false
        self.accountID = accountID
        self.imapConnectInfo = nil
        self.smtpConnectInfo = nil
    }
}

/**
 Some information about a list of operations needed to sync a single account.
 */
class OperationLine {
    let accountInfo: AccountConnectInfo
    let operations: [Operation]
    let finalOperation: Operation
    let errorContainer: ServiceErrorProtocol

    init(accountInfo: AccountConnectInfo, operations: [Operation], finalOperation: Operation,
         errorContainer: ServiceErrorProtocol) {
        self.accountInfo = accountInfo
        self.operations = operations
        self.finalOperation = finalOperation
        self.errorContainer = errorContainer
    }
}

extension OperationLine: ServiceErrorProtocol {
    var error: Error? {
        return errorContainer.error
    }

    func addError(_ error: Error) {
        errorContainer.addError(error)
    }

    func hasErrors() -> Bool {
        return errorContainer.hasErrors()
    }
}

/**
 Used for parameters/state shared between IMAP related operations.
 */
class ImapSyncData: ImapConnectionManagerProtocol {
    let connectInfo: EmailConnectInfo

    public var sync: ImapSync?

    var supportsIdle: Bool {
        return sync?.supportsIdle ?? false
    }

    init(connectInfo: EmailConnectInfo) {
        self.connectInfo = connectInfo
    }

    func imapConnection(connectInfo: EmailConnectInfo) -> ImapSync? {
        if self.connectInfo == connectInfo {
            return sync
        }
        return nil
    }

    public func reset() {
        sync = nil
    }
}

open class SmtpSendData {
    let connectInfo: EmailConnectInfo
    public var smtp: SmtpSend?

    init(connectInfo: EmailConnectInfo) {
        self.connectInfo = connectInfo
    }

    public func reset() {
        smtp = nil
    }
}
