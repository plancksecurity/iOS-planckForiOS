//
//  FetchNumberOfNewMailsService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import pEpIOSToolbox

/// Figures out the number of new (to us) messages in Inbox, taking all verified accounts
/// into account.
class FetchNumberOfNewMailsService {
    private var imapConnectionCache: ImapConnectionCache
    private let context: NSManagedObjectContext
    private let workerQueue = DispatchQueue(
        label: "NetworkService", qos: .background, target: nil)
    private let backgroundQueue = OperationQueue()
    private var errorContainer: ErrorContainerProtocol?

    init(imapConnectionDataCache: ImapConnectionCache? = nil,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol? = ErrorPropagator()) {
        self.context = context ?? Stack.shared.newPrivateConcurrentContext
        self.imapConnectionCache = imapConnectionDataCache ?? ImapConnectionCache()
        self.errorContainer = errorContainer
    }

    /// Starts the service
    ///
    /// - Parameter completionBlock: called when the service has finished.
    ///                              Passes nil if we could not figure out whether or not
    ///                              there are new emails.
    public func start(completionBlock: @escaping (_ numNewMails: Int?) -> ()) {
        workerQueue.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.context.performAndWait {
                let numNewMails = me.numberOfNewMails()
                if me.errorContainer?.hasErrors ?? false {
                    completionBlock(nil)
                } else {
                    completionBlock(numNewMails)
                }
            }
        }
    }

    /// Cancels all background tasks.
    public func stop() {
        backgroundQueue.cancelAllOperations()
    }

    // MARK: - Internal

    private func fetchAccounts() -> [CdAccount] {
        return CdAccount.all(in: context) ?? []
    }

    private func gatherConnectInfos() -> [EmailConnectInfo] {
        var connectInfos = [EmailConnectInfo]()
        for ci in imapConnectionCache.connectInfos {
            connectInfos.append(ci)
        }
        if connectInfos.isEmpty {
            for cdAccount in fetchAccounts() {
                guard let imapConnectInfo = cdAccount.imapConnectInfo else {
                    continue
                }
                connectInfos.append(imapConnectInfo)
            }
        }
        return connectInfos
    }

    private func numberOfNewMails() -> Int {
        let theErrorContainer = ErrorPropagator()
        errorContainer = theErrorContainer
        let cis = gatherConnectInfos()
        var result = 0
        for connectInfo in cis {
            let imapSyncConnection = imapConnectionCache.imapConnection(for: connectInfo)
            let loginOp = LoginImapOperation(parentName: #function,
                                             errorContainer: theErrorContainer,
                                             imapConnection: imapSyncConnection)
            let fetchNumNewMailsOp = FetchNumberOfNewMailsOperation(imapConnection: imapSyncConnection) {
                (numNewMails: Int?) in
                if let safeNewMails = numNewMails {
                    result += safeNewMails
                }
            }
            fetchNumNewMailsOp.addDependency(loginOp)
            backgroundQueue.addOperations([loginOp, fetchNumNewMailsOp], waitUntilFinished: false)
        }
        backgroundQueue.waitUntilAllOperationsAreFinished()

        return result
    }
}
