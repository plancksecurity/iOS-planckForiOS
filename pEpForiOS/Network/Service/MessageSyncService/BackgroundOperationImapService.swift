//
//  BackgroundOperationImapService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class BackgroundOperationImapService: AtomicImapService {
    let imapSyncData: ImapSyncData

    init(parentName: String = #function, backgrounder: BackgroundTaskProtocol? = nil,
         imapSyncData: ImapSyncData) {
        self.imapSyncData = imapSyncData
        super.init(parentName: parentName, backgrounder: backgrounder)
    }

    func cancel() {
        backgroundQueue.cancelAllOperations()
    }
}
