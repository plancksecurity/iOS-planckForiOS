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
    public enum EncryptAndSendOnceError: Error {
        case notImplemented
    }

    // Does nothing, but keeps the compiler compiling
    public init() {
    }

    public func sendAllOutstandingMessages(completion: @escaping (_ error: Error?) -> ()) {
        privateMoc.perform { [weak self] in
            guard let me = self else {
                // Assume this is an error, since there is no UI involved,
                // that can go out of scope
                Log.shared.lostMySelf()
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
        for sender in allSendersThatCanBeCanceled {
            sender.stop()
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
            controlQueue.async {
            }
        }

        func endBackgroundTask(for client: AnyHashable) throws {
            controlQueue.async {
                // TODO
                // completion(EncryptAndSendOnceError.notImplemented)
            }
        }

        private let completion: (_ error: Error?) -> ()
        private let errorPropagator: ErrorContainerProtocol
        private let controlQueue: DispatchQueue
    }
}
