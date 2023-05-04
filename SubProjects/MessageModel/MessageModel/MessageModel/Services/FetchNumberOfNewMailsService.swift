//
//  FetchNumberOfNewMailsService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PlanckToolbox

/// Figures out the number of new (to us) messages in Inbox, taking all verified accounts
/// into account.
class FetchNumberOfNewMailsService { //BUFF: should inmherit from operationBasedService
    private var imapConnectionCache: ImapConnectionCache
    private let context: NSManagedObjectContext
    private let workerQueue = DispatchQueue(
        label: "NetworkService", qos: .background, target: nil)
    private let backgroundQueue = OperationQueue()

    init(imapConnectionDataCache: ImapConnectionCache? = nil,
         context: NSManagedObjectContext? = nil) {
        self.context = context ?? Stack.shared.newPrivateConcurrentContext
        self.imapConnectionCache = imapConnectionDataCache ?? ImapConnectionCache()
    }

    /// Starts the service
    ///
    /// - Parameter completionBlock: called when the service has finished.
    ///                              Passes nil if we could not figure out whether or not
    ///                              there are new emails.
    func start(completionBlock: @escaping (_ numNewMails: Int?) -> ()) {
        workerQueue.async { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.context.performAndWait {
                let numNewMails = me.numberOfNewMails()
                completionBlock(numNewMails)
            }
        }
    }

    /// Cancels all background tasks.
    func stop() {
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
        let cis = gatherConnectInfos()
        var result = 0
        for connectInfo in cis {
            let errorContainer = ErrorPropagator(subscriber: self)
            let imapSyncConnection = imapConnectionCache.imapConnection(for: connectInfo)
            let loginOp = LoginImapOperation(parentName: #function,
                                             errorContainer: errorContainer,
                                             imapConnection: imapSyncConnection)
            let fetchNumNewMailsOp = FetchNumberOfNewMailsOperation(errorContainer: errorContainer,
                                                                    imapConnection: imapSyncConnection) {
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

extension FetchNumberOfNewMailsService: ErrorPropagatorSubscriber {
    func error(propagator: ErrorPropagator, error: Error) {
        Log.shared.error("One of our operations reported this error: %@", error.localizedDescription)
    }
}
