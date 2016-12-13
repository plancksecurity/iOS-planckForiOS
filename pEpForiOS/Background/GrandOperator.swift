//
//  GrandOperator.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

public typealias GrandOperatorCompletionBlock = (_ error: NSError?) -> Void

open class GrandOperator {
    public var sendLayerDelegate: SendLayerDelegate? = nil

    let comp = "GrandOperator"

    open let connectionManager: ConnectionManager

    fileprivate let verificationQueue = OperationQueue()

    public init(connectionManager: ConnectionManager) {
        self.connectionManager = connectionManager
    }

    /**
     Asynchronously verifies the given `EmailConnectInfo`s.
     */
    open func verify(
        account: CdAccount, emailConnectInfos: [EmailConnectInfo: CdServerCredentials],
        completionBlock: GrandOperatorCompletionBlock?) {

        // The operations that will be run
        var ops = [VerifyServiceOperation]()

        /// Creates a completion block for a verification operation.
        /// Has to find out if the verification was successful, and if it was, will set
        /// `needsVerification` to `false`.
        func mkCompletionBlock(op: VerifyServiceOperation,
                               credential: CdServerCredentials) -> (() -> Void)? {
            let ctx = credential.managedObjectContext!
            return {
                if !op.hasErrors() {
                    ctx.performAndWait {
                        credential.needsVerification = false
                    }
                }
            }
        }

        /// Add a `VerifyServiceOperation` to the operations to run, and give it a completion
        /// block created with `mkCompletionBlock`.
        func add(operation: VerifyServiceOperation, credentials: CdServerCredentials?) {
            guard let cred = credentials else {
                Log.error(component: comp,
                          errorString: "Cannot add VerifyServiceOperation without credentials")
                return
            }
            operation.completionBlock = mkCompletionBlock(op: operation, credential: cred)
            ops.append(operation)
        }

        for ci in emailConnectInfos.keys {
            if let prot = ci.emailProtocol {
                switch prot {
                case .imap:
                    add(operation: VerifyImapConnectionOperation(
                        connectionManager: connectionManager, connectInfo: ci),
                        credentials:  emailConnectInfos[ci]!)
                case .smtp:
                    add(operation: VerifySmtpConnectionOperation(
                        connectionManager: connectionManager, connectInfo: ci),
                        credentials:  emailConnectInfos[ci]!)
                }
            }
        }

        verificationQueue.batch(operations: ops, completionBlock: {
            var error: NSError?
            for op in ops {
                if op.hasErrors() {
                    error = op.errors.last
                    break
                }
            }
            if error == nil {
                let ctx = account.managedObjectContext!
                ctx.performAndWait {
                    account.needsVerification = false
                    Record.save(context: ctx)
                }
            }
            completionBlock?(error)
        })
    }
}
