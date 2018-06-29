//
//  MessageSyncServiceProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 01.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

protocol MessageSyncServiceFolderDelegate {
    /**
     The folders were fetched for the indicated account.
     */
    func didFetchFolders(forAccount: Account)
}

protocol MessageSyncServiceSentDelegate: class {
    /**
     The indicated message has been sent, as requested.
     */
    func didSend(message: Message)

    /**
     The indicated message IDs have been sent, regardless whether requested or not.
     */
    func didSend(messageIDs: [MessageID])
}

protocol MessageSyncServiceErrorDelegate: class {
    /**
     An error occurred, and should usually displayed.
     */
    func show(error: Error)
}

protocol MessageSyncServiceSyncDelegate: class {
    /**
     Called when the given account just got synced, and the service will enter idling.
     */
    func didSync(account: Account)
}

protocol MessageSyncServiceStateDelegate: class {
    /**
     Called when the state reaches the idling (or polling) phase.
     */
    func startIdling(account: Account)
}

protocol MessageSyncFlagsUploadDelegate: class {
    /**
     Called when local flags have been updated on the server.
     */
    func flagsUploaded(message: Message)
}

/**
 Message sync related actions that can be requested by the UI.
 The purpose is to make network-related actions seem as fast as possible,
 even with accounts that have to be polled, while still letting the backend
 have full control over the scheduling.
 */
protocol MessageSyncServiceProtocol {
    var errorDelegate: MessageSyncServiceErrorDelegate? { get set }
    var sentDelegate: MessageSyncServiceSentDelegate? { get set }
    var syncDelegate: MessageSyncServiceSyncDelegate? { get set }
    var stateDelegate: MessageSyncServiceStateDelegate? { get set }
    var flagsUploadDelegate: MessageSyncFlagsUploadDelegate? { get set }

    /**
     Request account verification, receiving news via the delegate.
     Backend might start syncing the inbox as soon as the verification
     was successful.
     */
    func requestVerification(account: Account, delegate: AccountVerificationServiceDelegate)

    func requestFetchOlderMessages(inFolder folder: Folder)

    /**
     Requests the given message to be drafted.
     */
    func requestDraft(message: Message)

    /**
     Notify the backend that the user just finished creating a message for sending,
     which should be sent out as fast as possible.
     */
    func requestSend(message: Message)

    /**
     Notify the backend that the user changed flags for the given message.
     The changes should be propagated as fast as possible to the server.
     */
    func requestFlagChange(message: Message)

    /**
     Message changes will be delivered via the `MessageFolderDelegate` mechanism.
     Backend may sync the inbox even if the UI never requested it.
     */
    func requestMessageSync(folder: Folder)

    /**
     Starts syncing folders, INBOX etc.
     */
    func start(account: Account)

    /**
     Cancels syncing the given account.
     */
    func cancel(account: Account)
}
