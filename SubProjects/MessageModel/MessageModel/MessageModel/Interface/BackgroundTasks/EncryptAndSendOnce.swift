//
//  EncryptAndSendOnce.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 11.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import pEpIOSToolbox

public class EncryptAndSendOnce: EncryptAndSendOnceProtocol {
    // Does nothing, but keeps the compiler compiling
    public init() {
    }

    public func sendAllOutstandingMessages(completion: @escaping (_ error: Error?) -> ()) {
        privateMoc.perform { [weak self] in
            guard let me = self else {
                // Assume this is an error, since there is no UI involved,
                // that can go out of scope
                Log.shared.lostMySelf()
                completion(nil)
                return
            }

            let errorPropagator = ErrorPropagator()
            let backgroundTaskManager = BackgroundTaskManager(completion: completion,
                                                              errorPropagator: errorPropagator)

            let allCdAccounts = CdAccount.all(in: me.privateMoc) as? [CdAccount] ?? []

            let allSenders = allCdAccounts.compactMap() {
                $0.sendService(backgroundTaskManager: backgroundTaskManager,
                               errorPropagator: errorPropagator)
            }

            me.allSendersThatCanBeCanceled = allSenders

            for sender in allSenders {
                sender.start()
            }
        }
    }

    public func cancel() {
        let allSenders = allSendersThatCanBeCanceled

        // all senders (SendServiceProtocol) were created on this queue,
        // so cancel them on it as well
        privateMoc.perform {
            for sender in allSenders {
                sender.stop()
            }
        }
    }

    // MARK: Private Member Variables

    private let privateMoc = Stack.shared.newPrivateConcurrentContext
    private var allSendersThatCanBeCanceled: [SendServiceProtocol] = []

    // MARK: Private Classes

    private class BackgroundTaskManager: BackgroundTaskManagerProtocol {
        init(completion: @escaping (_ error: Error?) -> (),
             errorPropagator: ErrorContainerProtocol) {
            self.completion = completion
            self.errorPropagator = errorPropagator
            controlQueue = DispatchQueue(label: "EncryptAndSendOnceControlQueue")
        }

        func startBackgroundTask(for client: AnyHashable,
                                 expirationHandler handler: (() -> Void)?) throws {
            controlQueue.async { [weak self] in
                guard let me = self else {
                    // Assume this is an error, since there is no UI involved,
                    // that can go out of scope
                    Log.shared.lostMySelf()
                    return
                }
                me.runningTasks.add(client)
            }
        }

        func endBackgroundTask(for client: AnyHashable) throws {
            controlQueue.async { [weak self] in
                guard let me = self else {
                    // Assume this is an error, since there is no UI involved,
                    // that can go out of scope
                    Log.shared.lostMySelf()
                    return
                }
                me.runningTasks.remove(client)
                if me.runningTasks.count == 0 {
                    if let theError = me.errorPropagator.error {
                        me.completion(theError)
                    } else {
                        me.completion(nil)
                    }
                }
            }
        }

        private let completion: (_ error: Error?) -> ()
        private let errorPropagator: ErrorContainerProtocol
        private let controlQueue: DispatchQueue
        private let runningTasks = NSMutableSet()
    }
}
