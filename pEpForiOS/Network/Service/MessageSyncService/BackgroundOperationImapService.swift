//
//  BackgroundOperationImapService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class BackgroundOperationImapService: AtomicImapService {
    var executingOperations = [Operation]()

    let imapSyncData: ImapSyncData

    init(parentName: String?, backgrounder: BackgroundTaskProtocol? = nil,
         imapSyncData: ImapSyncData) {
        self.imapSyncData = imapSyncData
        super.init(parentName: parentName, backgrounder: backgrounder)
    }

    func cancel() {
        for op in executingOperations {
            op.cancel()
        }
        executingOperations.removeAll()
        imapSyncData.sync?.delegate = nil
    }
}
