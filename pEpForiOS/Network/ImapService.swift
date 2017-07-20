//
//  ImapService
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

public protocol ImapSyncDelegate: class {
    func authenticationCompleted(_ sync: ImapSync, notification: Notification?)
    func authenticationFailed(_ sync: ImapSync, notification: Notification?)
    func connectionLost(_ sync: ImapSync, notification: Notification?)
    func connectionTerminated(_ sync: ImapSync, notification: Notification?)
    func connectionTimedOut(_ sync: ImapSync, notification: Notification?)
    func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?)
    func folderSyncCompleted(_ sync: ImapSync, notification: Notification?)
    func folderSyncFailed(_ sync: ImapSync, notification: Notification?)
    func messageChanged(_ sync: ImapSync, notification: Notification?)
    func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?)
    func folderOpenCompleted(_ sync: ImapSync, notification: Notification?)
    func folderOpenFailed(_ sync: ImapSync, notification: Notification?)
    func folderStatusCompleted(_ sync: ImapSync, notification: Notification?)
    func folderListCompleted(_ sync: ImapSync, notification: Notification?)
    func folderNameParsed(_ sync: ImapSync, notification: Notification?)
    func folderAppendCompleted(_ sync: ImapSync, notification: Notification?)
    func folderAppendFailed(_ sync: ImapSync, notification: Notification?)
    func messageStoreCompleted(_ sync: ImapSync, notification: Notification?)
    func messageStoreFailed(_ sync: ImapSync, notification: Notification?)
    func folderCreateCompleted(_ sync: ImapSync, notification: Notification?)
    func folderCreateFailed(_ sync: ImapSync, notification: Notification?)
    func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?)
    func folderDeleteFailed(_ sync: ImapSync, notification: Notification?)
    func badResponse(_ sync: ImapSync, response: String?)
    func actionFailed(_ sync: ImapSync, response: String?)
    func idleNewMessages(_ sync: ImapSync, notification: Notification?)
}

open class ImapSync: Service {
    public struct ImapState {
        var authenticationCompleted = false
        var currentFolderName: String?
        var currentFolder: CWIMAPFolder?
        var hasError = false
    }

    open override var comp: String { get { return "ImapSync" } }

    static open let defaultImapInboxName = "INBOX"

    let nonExistantMailboxName = MessageID.generate()

    weak open var delegate: ImapSyncDelegate?

    open var maxPrefetchCount: UInt = 20

    var capabilities: Set<String> {
        return service.capabilities()
    }

    var supportsIdle: Bool {
        return capabilities.contains("IDLE") || capabilities.contains("idle")
    }

    open var folderBuilder: CWFolderBuilding? {
        set {
            imapStore.folderBuilder = newValue
            imapStore.folderBuilder?.folderNameToIgnore = nonExistantMailboxName
        }
        get {
            return imapStore.folderBuilder
        }
    }

    open var folderNames: [String]? {
        if let folders = imapStore.folderEnumerator() {
            return folders.allObjects as? [String]
        }
        return nil
    }

    open var imapState = ImapState()

    var imapStore: CWIMAPStore {
        get {
            return service as! CWIMAPStore
        }
    }

    override func createService() -> CWService {
        return CWIMAPStore(name: connectInfo.networkAddress,
                           port: UInt32(connectInfo.networkPort),
                           transport: connectInfo.connectionTransport!)
    }

    override open func start() {
        (service as! CWIMAPStore).maxPrefetchCount = maxPrefetchCount
        super.start()
    }

    open override func cancel() {
        imapStore.folderBuilder = nil
        super.cancel()
    }

    open override func close() {
        imapState.currentFolder = nil
        super.close()
    }

    /**
     Opens the given mailbox (by name). If already open, do nothing.
     - Returns: true if the mailbox had to opened, false if it already was open.
     */
    @discardableResult open func openMailBox(name: String) -> Bool {
        if let currentFolderName = imapState.currentFolderName,
            currentFolderName == name {
            imapState.currentFolder = imapStore.folder(forName: name) as? CWIMAPFolder
            return false
        } else {
            imapState.currentFolderName = nil
            imapState.currentFolder = nil
            // Note: If you open a folder with PantomimeReadOnlyMode,
            // all messages will be prefetched by default,
            // independent of the prefetch parameter.
            let fol = imapStore.folder(forName: name, mode: PantomimeReadWriteMode)
            imapState.currentFolder = fol
            if let folder = fol {
                Log.info(component: comp, content: "openMailBox have to open \(folder.name())")
                return true
            }
            return false
        }
    }

    /**
     Unselects the current mailbox by selecting a mailbox that doesn't exist
     on the server.
     */
    @discardableResult open func unselectCurrentMailBox() -> Bool {
        if imapState.currentFolderName == nil {
            return false
        }
        return openMailBox(name: nonExistantMailboxName)
    }

    func openFolder() throws -> CWIMAPFolder {
        guard let folderName = imapState.currentFolderName else {
            throw Constants.errorIllegalState(
                comp,
                stateName: NSLocalizedString("No open folder",
                                             comment: "Need an open folder to sync messages"))
        }
        guard let folder = imapStore.folder(forName: imapState.currentFolderName) else {
            throw Constants.errorFolderNotOpen(comp, folderName: folderName)
        }
        return folder as! CWIMAPFolder
    }

    open func fetchMessages() throws {
        let folder = try openFolder()
        folder.prefetch()
    }

    open func syncMessages(firstUID: UInt, lastUID: UInt) throws {
        let folder = try openFolder()
        folder.syncExistingFirstUID(firstUID, lastUID: lastUID)
    }

    open func createFolderWithName(_ folderName: String) {
        // The only relevant parameter here is folderName, all others are
        // ignored by pantomime.
        imapStore.createFolder(withName: folderName, type: PantomimeFormatFolder,
                                       contents: nil)
    }

    open func deleteFolderWithName(_ folderName: String) {
        imapStore.deleteFolder(withName: folderName)
    }

    /**
     Sends the IDLE command to the server, and enters thas state.
     */
    open func sendIdle() {
        if imapState.hasError || !imapState.authenticationCompleted ||
            imapState.currentFolder == nil {
            return
        }
        imapStore.send(IMAP_IDLE, info: nil, string: "IDLE")
    }

    open func exitIdle() {
        imapStore.exitIDLE()
    }
}

extension ImapSync: CWServiceClient {
    @objc public func authenticationCompleted(_ notification: Notification?) {
        dumpMethodName("authenticationCompleted", notification: notification)
        imapState.authenticationCompleted = true
        delegate?.authenticationCompleted(self, notification: notification)
    }

    @objc public func authenticationFailed(_ notification: Notification?) {
        dumpMethodName("authenticationFailed", notification: notification)
        delegate?.authenticationFailed(self, notification: notification)
    }

    @objc public func connectionEstablished(_ notification: Notification?) {
        dumpMethodName("connectionEstablished", notification: notification)
    }

    @objc public func connectionLost(_ notification: Notification?) {
        dumpMethodName("connectionLost", notification: notification)
        imapState.authenticationCompleted = false
        delegate?.connectionLost(self, notification: notification)
    }

    @objc public func connectionTerminated(_ notification: Notification?) {
        dumpMethodName("connectionTerminated", notification: notification)
        imapState.authenticationCompleted = false
        delegate?.connectionTerminated(self, notification: notification)
    }

    @objc public func connectionTimedOut(_ notification: Notification?) {
        dumpMethodName("connectionTimedOut", notification: notification)
        imapState.authenticationCompleted = false
        delegate?.connectionTimedOut(self, notification: notification)
    }

    @objc public func folderPrefetchCompleted(_ notification: Notification?) {
        dumpMethodName("folderPrefetchCompleted", notification: notification)
        if let folder: CWFolder = ((notification as NSNotification?)?.userInfo?["Folder"]
            as? CWFolder) {
            Log.info(component: comp, content: "prefetched folder: \(folder.name())")
        } else {
            Log.info(component: comp, content: "folderPrefetchCompleted: \(String(describing: notification))")
        }
        if let bq = folderBuilder?.backgroundQueue {
            // Wait until all newly synced messages are stored
            bq.waitUntilAllOperationsAreFinished()
        }
        delegate?.folderPrefetchCompleted(self, notification: notification)
    }

    @objc public func folderSyncCompleted(_ notification: Notification?) {
        dumpMethodName("folderSyncCompleted", notification: notification)
        if let folder: CWFolder = ((notification as NSNotification?)?.userInfo?["Folder"]
            as? CWFolder) {
            Log.info(component: comp, content: "synced folder: \(folder.name())")
        } else {
            Log.info(component: comp, content: "folderSyncCompleted: \(String(describing: notification))")
        }
        if let bq = folderBuilder?.backgroundQueue {
            // Wait until all newly synced messages are stored
            bq.waitUntilAllOperationsAreFinished()
        }
        delegate?.folderSyncCompleted(self, notification: notification)
    }

    @objc public func folderSyncFailed(_ notification: Notification?) {
        dumpMethodName("folderSyncFailed", notification: notification)
        if let bq = folderBuilder?.backgroundQueue {
            // Wait until all newly synced messages are stored
            bq.waitUntilAllOperationsAreFinished()
        }
        delegate?.folderSyncFailed(self, notification: notification)
    }

    @objc public func messagePrefetchCompleted(_ notification: Notification?) {
        dumpMethodName("messagePrefetchCompleted", notification: notification)
        delegate?.messagePrefetchCompleted(self, notification: notification)
    }

    @objc public func serviceInitialized(_ notification: Notification?) {
        dumpMethodName("serviceInitialized", notification: notification)

        if let loginName = connectInfo.loginName,
            let loginPassword = connectInfo.loginPassword {
            imapStore.authenticate(loginName,
                                   password: loginPassword,
                                   mechanism: bestAuthMethod().rawValue)
        } else {
            if connectInfo.loginPassword == nil {
                Log.error(component: comp, errorString: "Want to login, but don't have a password")
            }
            if connectInfo.loginName == nil {
                Log.error(component: comp, errorString: "Want to login, but don't have a login")
            }
            delegate?.authenticationFailed(self, notification: notification)
        }
    }

    @objc public func serviceReconnected(_ theNotification: Notification?) {
        dumpMethodName("serviceReconnected", notification: theNotification)
    }

    @objc public func service(_ theService: CWService, sentData theData: Data) {
    }

    @objc public func service(_ theService: CWService, receivedData theData: Data) {
    }

    @objc public func messageChanged(_ notification: Notification?) {
        dumpMethodName("messageChanged", notification: notification)
        delegate?.messageChanged(self, notification: notification)
    }

    @objc public func folderStatusCompleted(_ notification: Notification?) {
        dumpMethodName("folderStatusCompleted", notification: notification)
        delegate?.folderStatusCompleted(self, notification: notification)
    }

    @objc public func actionFailed(_ notification: Notification?) {
        dumpMethodName("actionFailed", notification: notification)

        guard
            let userInfo = (notification as NSNotification?)?.userInfo,
            let errorInfoDict = userInfo[PantomimeErrorInfo] as? NSDictionary,
            let responseString = errorInfoDict[PantomimeBadResponseInfoKey] as? String
            else {
                delegate?.badResponse(self, response: nil)
                return
        }
        delegate?.badResponse(self, response: responseString)
    }

    @objc public func messageStoreCompleted(_ notification: Notification?) {
        dumpMethodName("messageStoreCompleted", notification: notification)
        delegate?.messageStoreCompleted(self, notification: notification)
    }

    @objc public func messageStoreFailed(_ notification: Notification?) {
        dumpMethodName("messageStoreFailed", notification: notification)
        delegate?.messageStoreFailed(self, notification: notification)
    }

    @objc public func folderCreateCompleted(_ notification: Notification?) {
        dumpMethodName("folderCreateCompleted", notification: notification)
        delegate?.folderCreateCompleted(self, notification: notification)
    }

    @objc public func folderCreateFailed(_ notification: Notification?) {
        dumpMethodName("folderCreateFailed", notification: notification)
        delegate?.folderCreateFailed(self, notification: notification)
    }

    @objc public func folderDeleteCompleted(_ notification: Notification?) {
        dumpMethodName("folderDeleteCompleted", notification: notification)
        delegate?.folderDeleteCompleted(self, notification: notification)
    }

    @objc public func folderDeleteFailed(_ notification: Notification?) {
        dumpMethodName("folderDeleteFailed", notification: notification)
        delegate?.folderDeleteFailed(self, notification: notification)
    }

    @objc public func idleNewMessages(_ notification: Notification?) {
        dumpMethodName("idleNewMessages", notification: notification)
        delegate?.idleNewMessages(self, notification: notification)
    }
}

extension ImapSync: PantomimeFolderDelegate {
    @objc public func folderOpenCompleted(_ notification: Notification?) {
        if let folder: CWFolder = ((notification as NSNotification?)?.userInfo?["Folder"]
            as? CWFolder) {
            Log.info(component: comp, content: "folderOpenCompleted: \(folder.name())")
            imapState.currentFolderName = folder.name()
        } else {
            Log.info(component: comp, content: "folderOpenCompleted: \(String(describing: notification))")
            imapState.currentFolderName = nil
        }
        delegate?.folderOpenCompleted(self, notification: notification)
    }

    @objc public func folderOpenFailed(_ notification: Notification?) {
        if let folder: CWFolder = ((notification as NSNotification?)?.userInfo?["Folder"]
            as? CWFolder) {
            Log.info(component: comp, content: "folderOpenFailed: \(folder.name())")
        } else {
            Log.info(component: comp, content: "folderOpenFailed: \(String(describing: notification))")
        }
        delegate?.folderOpenFailed(self, notification: notification)
    }

    @objc public func folderListCompleted(_ notification: Notification?) {
        dumpMethodName("folderListCompleted", notification: notification)
        delegate?.folderListCompleted(self, notification: notification)
    }

    @objc public func folderNameParsed(_ notification: Notification?) {
        dumpMethodName("folderNameParsed", notification: notification)
        delegate?.folderNameParsed(self, notification: notification)
    }

    @objc public func folderAppendCompleted(_ notification: Notification?) {
        dumpMethodName("folderAppendCompleted", notification: notification)
        delegate?.folderAppendCompleted(self, notification: notification)
    }

    @objc public func folderAppendFailed(_ notification: Notification?) {
        dumpMethodName("folderAppendFailed", notification: notification)
        delegate?.folderAppendFailed(self, notification: notification)
    }
}
