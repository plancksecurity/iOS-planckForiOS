//
//  QuickSyncService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

public enum QuickSyncResult {
    case failed
    case noData
    case fetchedData
}

public typealias QuickSyncCompletionBlock = (QuickSyncResult) -> ()

open class QuickSyncService {
    var imapConnectionDataCache: [EmailConnectInfo: ImapSyncData]
    let context = Record.Context.background
    let workerQueue = DispatchQueue(
        label: "NetworkService", qos: .utility, target: nil)
    let backgroundQueue = OperationQueue()
    var errorContainer: ErrorContainer?

    public init(imapConnectionDataCache: [EmailConnectInfo: ImapSyncData]?) {
        self.imapConnectionDataCache = imapConnectionDataCache ?? [EmailConnectInfo: ImapSyncData]()
    }

    func fetchAccounts() -> [CdAccount] {
        let p = NSPredicate(format: "needsVerification = false")
        return CdAccount.all(predicate: p, in: context) as? [CdAccount] ?? []
    }

    func gatherConnectInfos() -> [EmailConnectInfo] {
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

    public func sync(completionBlock: @escaping QuickSyncCompletionBlock) {
        workerQueue.async {
            self.kickOffOperationsAndWait()
            if self.errorContainer?.hasErrors() ?? false {
                completionBlock(.failed)
            } else {
                completionBlock(.fetchedData)
            }
        }
    }

    func kickOffOperationsAndWait() {
        let theErrorContainer = ErrorContainer()
        errorContainer = theErrorContainer
        let cis = gatherConnectInfos()
        for connectInfo in cis {
            let imapSyncData = ServiceUtil.cachedImapSync(
                imapConnectionDataCache: imapConnectionDataCache, connectInfo: connectInfo)
            let loginOp = LoginImapOperation(
                parentName: #function, errorContainer: theErrorContainer,
                imapSyncData: imapSyncData)
            loginOp.completionBlock = {

            }
            backgroundQueue.addOperation(loginOp)
        }
        backgroundQueue.waitUntilAllOperationsAreFinished()
    }
}
