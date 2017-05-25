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
    public let needsVerification: Bool
    public let accountID: NSManagedObjectID
    public let imapConnectInfo: EmailConnectInfo?
    public let smtpConnectInfo: EmailConnectInfo?
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
open class ImapSyncData: ImapConnectionManagerProtocol {
    public let connectInfo: EmailConnectInfo

    public var sync: ImapSync?

    public init(connectInfo: EmailConnectInfo) {
        self.connectInfo = connectInfo
    }

    public func imapConnection(connectInfo: EmailConnectInfo) -> ImapSync? {
        if self.connectInfo == connectInfo {
            return sync
        }
        return nil
    }
}

open class SmtpSendData {
    public let connectInfo: EmailConnectInfo
    public var smtp: SmtpSend?

    public init(connectInfo: EmailConnectInfo) {
        self.connectInfo = connectInfo
    }
}
