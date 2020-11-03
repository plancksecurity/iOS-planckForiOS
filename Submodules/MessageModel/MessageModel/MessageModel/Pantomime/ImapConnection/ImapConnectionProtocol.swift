//
//  ImapConnectionProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 31.01.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

/// Wraps the Pantomime IMAP API.
/// You MUST use this to place IMAP related calls to Pantomime.
/// Conform to ImapSyncDelegate to get IMAP ralated Pantomime delegate calls.
protocol ImapConnectionProtocol {
    var delegate: ImapConnectionDelegate? { get set }

    /// Indicates if a client certificate was set for this connection.
    var isClientCertificateSet: Bool { get }

    /// Whether or not the server supports IMAP IDLE.
    var supportsIdle: Bool { get }

    /// Calls `CWIMAPStore`'s `listFolders`, which sends a LIST command to the server.
    ///
    /// Delegate gets `folderNameParsed` for each folder name sent by the server, and
    /// `folderListCompleted` when the LIST is completed.
    func listFolders()

    func start()

    func cancel()

    /// Opens the given mailbox (by name).  If already and exists count does not matter,
    /// do nothing.
    ///
    /// - Note: If you demand an EXISTS count (updateExistsCount is true), then in any
    ///    case a SELECT is sent to the server, and you will receive a
    ///    `folderOpenCompleted`.
    /// - Parameters:
    ///   - name: name of mailbox to open
    ///   - updateExistsCount: if true, exists count of the mailbox is updated
    /// - Returns: true if a SELECT was sent to the server, false if it already was open,
    ///    and there was no need for a SELECT command.
    @discardableResult func openMailBox(name: String,
                                        updateExistsCount: Bool) -> Bool

    // MARK: - DISPATCH TO INTERNAL STATE

    var hasError: Bool { get set }

    var authenticationCompleted: Bool { get }

    var isIdling: Bool { get }

    func resetMatchedUIDs()

    func existingUIDs() -> Set<AnyHashable>?

    // MARK: - CLOSE

    // TODO: This is only called in tests, but accesses internal data.
    func close()

    // MARK: - DISPATCH TO CONNECTINFO

    func cdAccount(moc: NSManagedObjectContext) -> CdAccount?

    func isTrusted(context: NSManagedObjectContext) -> Bool

    var accountAddress: String { get }

    // MARK: - FETCH & SYNC

    func fetchMessages() throws

    func fetchOlderMessages() throws

    func fetchUidsForNewMessages() throws

    func syncMessages(firstUID: UInt, lastUID: UInt, updateExistsCount: Bool) throws

    // MARK: - FOLDERS

    func createFolderNamed(_ folderName: String)

    func deleteFolderWithName(_ folderName: String)

    // MARK: - IDLE

    /// Sends the IDLE command to the server, and enters thas state.
    func sendIdle()

    func exitIdle()

    // MARK: - EXPUNGE

    /// EXPUNGEs the currently selected folder, deleting all messages marked as \Delete.
    func expunge() throws

    // MARK: - MOVE

    /// Sends a MOVE command for the given message UID to the given target folder name.
    func moveMessage(uid: UInt, toFolderWithName: String)

    // MARK: - STORE

    /// Sends a STORE command.
    func store(info: [AnyHashable : Any], command: String)

    // MARK: - COPY

    /// Sends a COPY command for the given message UID to the given target folder name.
    func copyMessage(uid: UInt, toFolderWithName: String)

    // MARK: - APPEND

    /// Sends an APPEND command.
    func append(messageData: Data,
                folderType: FolderType,
                folderName: String,
                internalDate: Date?,
                context: NSManagedObjectContext)
}
