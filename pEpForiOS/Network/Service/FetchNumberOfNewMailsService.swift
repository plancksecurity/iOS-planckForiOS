//
//  FetchNumberOfNewMailsService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

/// Figures out the number of new (to us) messages in Inbox, taking all verified accounts
/// into account.
open class FetchNumberOfNewMailsService {
    private var imapConnectionDataCache: [EmailConnectInfo: ImapSyncData]
    private let context = Record.Context.background
    private let workerQueue = DispatchQueue(
        label: "NetworkService", qos: .utility, target: nil)
    private let backgroundQueue = OperationQueue()
    private var errorContainer: ErrorContainer?

    public init(imapConnectionDataCache: [EmailConnectInfo: ImapSyncData]? = nil) {
        self.imapConnectionDataCache = imapConnectionDataCache ?? [EmailConnectInfo: ImapSyncData]()
    }

    /// Starts the service
    ///
    /// - Parameter completionBlock: called when the service has finished.
    ///                              Passes nil if we could not figure out whether or not
    ///                              there are new emails.
    public func start(completionBlock: @escaping (_ numNewMails: Int?) -> ()) {
        workerQueue.async {
            let numNewMails = self.numberOfNewMails()
            if self.errorContainer?.hasErrors() ?? false {
                completionBlock(nil)
            } else {
                completionBlock(numNewMails)
            }
        }
    }

    /// Cancels all background tasks.
    public func stop() {
        backgroundQueue.cancelAllOperations()
    }

    // MARK: - Internal

    private func fetchAccounts() -> [CdAccount] {
        let p = NSPredicate(format: "needsVerification = false")
        return CdAccount.all(predicate: p, in: context) as? [CdAccount] ?? []
    }

    private func gatherConnectInfos() -> [EmailConnectInfo] {
        var connectInfos = [EmailConnectInfo]()
        if !imapConnectionDataCache.isEmpty {
            for ci in imapConnectionDataCache.keys {
                connectInfos.append(ci)
            }
        }
        if connectInfos.isEmpty {
            let accountCIs = ServiceUtil.gatherConnectInfos(
                context: context, accounts: fetchAccounts())
            for aci in accountCIs {
                if let ici = aci.imapConnectInfo {
                    connectInfos.append(ici)
                }
            }
        }
        return connectInfos
    }

    private func numberOfNewMails() -> Int {
        let theErrorContainer = ErrorContainer()
        errorContainer = theErrorContainer
        let cis = gatherConnectInfos()
        var result = 0
        for connectInfo in cis {
            let imapSyncData = ServiceUtil.cachedImapSync(
                imapConnectionDataCache: imapConnectionDataCache, connectInfo: connectInfo)
            let loginOp = LoginImapOperation(
                parentName: #function, errorContainer: theErrorContainer,
                imapSyncData: imapSyncData)
            backgroundQueue.addOperation(loginOp)
            let fetchNumNewMailsOp = FetchNumberOfNewMailsOperation(imapSyncData: imapSyncData) {
                (numNewMails: Int?) in
                if let safeNewMails = numNewMails {
                    result += safeNewMails
                }
            }
            fetchNumNewMailsOp.addDependency(loginOp)
            backgroundQueue.addOperation(fetchNumNewMailsOp)
        }
        backgroundQueue.waitUntilAllOperationsAreFinished()

        return result
    }
}
