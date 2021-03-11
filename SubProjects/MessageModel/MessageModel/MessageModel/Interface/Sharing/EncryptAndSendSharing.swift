//
//  EncryptAndSendSharing.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

#if canImport(BackgroundTasks)
    import BackgroundTasks
#endif

import PEPIOSToolboxForAppExtensions
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

            let errorPropagator = ErrorPropagator()
            let smtpConnection = SmtpConnection(connectInfo: smtpConnectInfo)

            // Login
            let loginOP = LoginSmtpOperation(smtpConnection: smtpConnection,
                                             errorContainer: errorPropagator)

            let sendOp = EncryptAndSMTPSendMessageOperation(cdMessageToSendObjectId: cdMessage.objectID,
                                                            smtpConnection: smtpConnection,
                                                            errorContainer: errorPropagator)

            sendOp.addDependency(loginOP)
            sendOp.completionBlock = { [weak self] in
                if errorPropagator.hasErrors {
                    if #available(iOS 13.0, *) {
                        // fall back to background task
                        guard let me = self else {
                            Log.shared.lostMySelf()
                            return
                        }
                        me.scheduleAppSend(completion: completion)
                    } else {
                        // signal the error
                        completion(errorPropagator.error)
                    }
                } else {
                    completion(nil)
                }
            }

            me.queue.addOperations([loginOP, sendOp], waitUntilFinished: false)
        }
    }

    // MARK: Private Member Variables

    private let privateMoc = Stack.shared.newPrivateConcurrentContext

    private let queue = OperationQueue()

    // MARK: Private Functions

    @available(iOS 13.0, *)
    private func scheduleAppSend(completion: @escaping (Error?) -> ()) {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskSend)
        // Send immediately, no need to wait
        request.earliestBeginDate = Date()

        do {
            try BGTaskScheduler.shared.submit(request)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}
