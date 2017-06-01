//
//  MessageSyncServiceProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Message sync related actions that can be requested by the UI.
 The purpose is to make network-related actions seem as fast as possible,
 even with accounts that have to be polled, while still letting the backend
 have full control over the scheduling.
 */
protocol MessageSyncServiceProtocol {
    /**
     Request account verification, receiving news via the delegate.
     Backend will probably start syncing the inbox as soon as the verification
     was successful.
     */
    func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate)

    /**
     Notify the backend that the user just finished creating a message for sending,
     which should be sent out as fast as possible.
     */
    func requestSend(message: Message)

    /**
     Message changes will be delivered via the `MessageFolderDelegate` mechanism.
     Backend may sync the inbox even if the UI never requested it.
     */
    func requestMessageSync(folder: Folder)
}
