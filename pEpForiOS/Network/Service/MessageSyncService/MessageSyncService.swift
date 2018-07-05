//
//  MessageSyncService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

class MessageSyncService: MessageSyncServiceProtocol {
    let parentName: String
    let managementQueue = DispatchQueue(label: "pep.security.MessageSyncService.managementQueue",
                                        qos: .utility,
                                        target: nil)
    var accountVerifications =
        [Account:(AccountVerificationService, AccountVerificationServiceDelegate)]()

    let fetchOlderImapMessagesService = FetchOlderImapMessagesService()

    init(parentName: String = #function) {
        self.parentName = parentName
    }

    private func requestVerificationInternal(account: Account,
                                             delegate: AccountVerificationServiceDelegate) {
        let service = AccountVerificationService()
        service.delegate = self
        accountVerifications[account] = (service, delegate)
        service.verify(account: account)
    }

    private func requestFetchOlderImapMessagesInternal(forFolder folder: Folder) {
        fetchOlderImapMessagesService.fetchOlderMessages(inFolder: folder)
    }
}

// MARK: - MessageSyncServiceProtocol

extension MessageSyncService {

    /**
     Request account verification, receiving news via the delegate.
     Backend might start syncing the inbox as soon as the verification
     was successful.
     */
    func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate) {
        managementQueue.async {
            self.requestVerificationInternal(account: account, delegate: delegate)
        }
    }

    func requestFetchOlderMessages(inFolder folder: Folder) {
        self.requestFetchOlderImapMessagesInternal(forFolder: folder)
    }
}

// MARK: - AccountVerificationServiceDelegate

extension MessageSyncService: AccountVerificationServiceDelegate {
    private func verifiedInternal(account: Account, service: AccountVerificationServiceProtocol,
                                  result: AccountVerificationResult) {
        guard let (service, delegate) = accountVerifications[account] else {
            Log.shared.errorComponent(#function, message: "no service")
            return
        }
        delegate.verified(account: account, service: service, result: result)
        accountVerifications[account] = nil
    }

    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        managementQueue.async {
            self.verifiedInternal(account: account, service: service, result: result)
        }
    }
}
