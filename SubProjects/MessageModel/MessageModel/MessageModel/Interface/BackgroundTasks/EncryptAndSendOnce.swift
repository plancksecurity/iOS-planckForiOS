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
            let backgroundTaskManager = BackgroundTaskManager()
            let errorPropagator = ErrorPropagator()

            let allCdAccounts = CdAccount.all(in: me.privateMoc) as? [CdAccount] ?? []

            let allSenders = allCdAccounts.compactMap() {
                $0.sendService(backgroundTaskManager: backgroundTaskManager,
                               errorPropagator: errorPropagator)
            }

            for sender in allSenders {
                sender.start()
            }

            completion(EncryptAndSendOnceError.notImplemented)
        }
    }

    public func cancel() {
    }

    // MARK: Private Member Variables

    private let privateMoc = Stack.shared.newPrivateConcurrentContext

    // MARK: Private Classes

    private class BackgroundTaskManager: BackgroundTaskManagerProtocol {
        func startBackgroundTask(for client: AnyHashable,
                                 expirationHandler handler: (() -> Void)?) throws {
        }

        func endBackgroundTask(for client: AnyHashable) throws {
        }
    }
}
