//
//  EncryptAndSendSharing.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData
import BackgroundTasks

import pEpIOSToolboxForExtensions
import pEp4iosIntern

public class EncryptAndSendSharing: EncryptAndSendSharingProtocol {
    public enum SendError: Error {
        case internalError
    }

    // Does nothing, for now, but the compiler insists.
    public init() {
    }

    public func send(message: Message, completion: @escaping (Error?) -> ()) {
        privateMoc.perform { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(message: "Lost self")
                completion(SendError.internalError)
                return
            }
            guard let cdMessage = message.cdMessage() else {
                Log.shared.errorAndCrash(message: "Message without corresponding CdMessage")
                completion(SendError.internalError)
                return
            }
            guard let cdAccount = cdMessage.parent?.account else {
                Log.shared.errorAndCrash(message: "CdMessage without corresponding CdAccount")
                completion(SendError.internalError)
                return
            }
            guard let smtpConnectInfo = cdAccount.smtpConnectInfo else {
                Log.shared.errorAndCrash(message: "CdAccount without SmtpConnectInfo")
                completion(SendError.internalError)
                return
            }
            guard let imapConnectInfo = cdAccount.imapConnectInfo else {
                Log.shared.errorAndCrash(message: "CdAccount without ImapConnectInfo")
                completion(SendError.internalError)
                return
            }

            let errorPropagator = ErrorPropagator()
            let smtpConnection = SmtpConnection(connectInfo: smtpConnectInfo)

            let loginImapOP = LoginSmtpOperation(smtpConnection: smtpConnection,
                                                 errorContainer: errorPropagator)

            let sendOp = EncryptAndSMTPSendMessageOperation(cdMessageToSendObjectId: cdMessage.objectID,
                                                            smtpConnection: smtpConnection,
                                                            errorContainer: errorPropagator)

            sendOp.addDependency(loginImapOP)

            let imapConnection = ImapConnection(connectInfo: imapConnectInfo)

            let loginImapOp = LoginImapOperation(errorContainer: errorPropagator,
                                                 imapConnection: imapConnection)

            loginImapOp.addDependency(sendOp)

            loginImapOp.completionBlock = {
                if errorPropagator.hasErrors {
                    // signal the error
                    completion(errorPropagator.error)
                } else {
                    completion(nil)
                }
            }

            me.queue.addOperations([loginImapOP, sendOp, loginImapOp],
                                   waitUntilFinished: false)
        }
    }

    // MARK: Private Member Variables

    private let privateMoc = Stack.shared.newPrivateConcurrentContext

    private let queue = OperationQueue()
}
