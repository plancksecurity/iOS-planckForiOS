//
//  MessageSyncService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

class MessageSyncService: MessageSyncServiceProtocol {
    let sleepTimeInSeconds: Double
    let backgrounder: BackgroundTaskProtocol?
    let mySelfer: KickOffMySelfProtocol?

    init(sleepTimeInSeconds: Double = 10.0,
         parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil,
         mySelfer: KickOffMySelfProtocol? = nil) {
        self.sleepTimeInSeconds = sleepTimeInSeconds
        self.backgrounder = backgrounder
        self.mySelfer = mySelfer
    }

    func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
        Log.shared.errorAndCrash(component: #function, errorString: "not implemented")
    }

    func requestSend(message: Message) {
        Log.shared.errorAndCrash(component: #function, errorString: "not implemented")
    }

    func requestMessageSync(folder: Folder) {
        Log.shared.errorAndCrash(component: #function, errorString: "not implemented")
    }
}
