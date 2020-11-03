//
//  ImapConnectionDelegate.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 31.01.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

protocol ImapConnectionDelegate: class {
    func authenticationCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func authenticationFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func connectionLost(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func connectionTerminated(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func connectionTimedOut(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderFetchCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderSyncCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderSyncFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func messageChanged(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func messagePrefetchCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderOpenFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderStatusCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderListCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderNameParsed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderAppendCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderAppendFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func messageStoreCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func messageStoreFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func messageUidMoveCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func messageUidMoveFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func messagesCopyCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func messagesCopyFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderCreateCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderCreateFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderDeleteCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderDeleteFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func badResponse(_ imapConnection: ImapConnectionProtocol, response: String?)
    func actionFailed(_ imapConnection: ImapConnectionProtocol, response: String?)
    func idleEntered(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func idleNewMessages(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func idleFinished(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
    func folderExpungeCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?)
}
