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

    var accountVerifications = [Account: AccountVerificationService]()

    init(sleepTimeInSeconds: Double = 10.0,
         parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil,
         mySelfer: KickOffMySelfProtocol? = nil) {
        self.sleepTimeInSeconds = sleepTimeInSeconds
        self.backgrounder = backgrounder
        self.mySelfer = mySelfer
    }

    func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
        let service = AccountVerificationService()
        service.delegate = delegate
        service.verify(account: account)
        accountVerifications[account] = service
    }

    func requestSend(message: Message) {
        Log.shared.errorAndCrash(component: #function, errorString: "not implemented")
    }

    func requestMessageSync(folder: Folder) {
        Log.shared.errorAndCrash(component: #function, errorString: "not implemented")
    }
}

extension MessageSyncService: AccountVerificationServiceDelegate {
    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        guard let service = accountVerifications[account] else {
            Log.shared.errorComponent(#function, message: "no service")
            return
        }
        service.delegate?.verified(account: account, service: service, result: result)
    }
}
