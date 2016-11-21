//
//  ImapService
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//
import MessageModel

public struct ImapState {
    var authenticationCompleted = false
    var currentFolder: String?
}

public protocol ImapSyncDelegate: class {
    func authenticationCompleted(_ sync: ImapSync, notification: Notification?)
    func authenticationFailed(_ sync: ImapSync, notification: Notification?)
    func connectionLost(_ sync: ImapSync, notification: Notification?)
    func connectionTerminated(_ sync: ImapSync, notification: Notification?)
    func connectionTimedOut(_ sync: ImapSync, notification: Notification?)
    func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?)
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

    /** General error indicator */
    func actionFailed(_ sync: ImapSync, error: NSError)
}

/**
 Default implementation of a delegate that does nothing.
 */
open class DefaultImapSyncDelegate: ImapSyncDelegate {
    public init() {
    }

    open func authenticationCompleted(_ sync: ImapSync, notification: Notification?)  {}
    open func authenticationFailed(_ sync: ImapSync, notification: Notification?)  {}
    open func connectionLost(_ sync: ImapSync, notification: Notification?)  {}
    open func connectionTerminated(_ sync: ImapSync, notification: Notification?)  {}
    open func connectionTimedOut(_ sync: ImapSync, notification: Notification?)  {}
    open func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?)  {}
    open func messageChanged(_ sync: ImapSync, notification: Notification?)  {}
    open func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?)  {}
    open func folderOpenCompleted(_ sync: ImapSync, notification: Notification?)  {}
    open func folderOpenFailed(_ sync: ImapSync, notification: Notification?)  {}
    open func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {}
    open func folderListCompleted(_ sync: ImapSync, notification: Notification?) {}
    open func folderNameParsed(_ sync: ImapSync, notification: Notification?) {}
    open func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {}
    open func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {}
    open func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {}
    open func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {}
    open func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {}
    open func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {}
    open func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {}
    open func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {}

    open func actionFailed(_ sync: ImapSync, error: NSError) {}
}

public enum ImapError: Int {
    case folderNotOpen = 1000
}

public protocol IImapSync {
    /**
     The delegate.
     */
    weak var delegate: ImapSyncDelegate? { get set }

    /**
     The maximum number of messages to prefetch in one gulp.
     */
    var maxPrefetchCount: UInt { get set }

    /**
     An instance of `CWFolderBuilding` can be used for persistence.
     */
    var folderBuilder: CWFolderBuilding? { get set }

    /**
     The list of all IMAP folders on the server.
     
     - Note: This will return nil the first time you access it. Try again when you have
     received `folderListCompleted`.
     */
    var folderNames: [String]? { get }

    /**
     Start to connect.
     */
    func start()

    /**
     Opens the folder with the given name, prefetching all emails contained if wanted.
     Should call this after receiving receivedFolderNames().
     */
    func openMailBox(_ name: String)

    /**
     Sync the mails from the curently selected folder.
     */
    func syncMails() throws

    /**
     Creates a new folder on the server.
     */
    func createFolderWithName(_ folderName: String)

    /**
     Deletes the folder with the given name from the server.
     */
    func deleteFolderWithName(_ folderName: String)

    /**
     Close the connection.
     */
    func close()
}

open class ImapSync: Service, IImapSync {
    open override var comp: String { get { return "ImapSync" } }

    static open let defaultImapInboxName = "INBOX"

    weak open var delegate: ImapSyncDelegate?
    open var maxPrefetchCount: UInt = 20

    open var folderBuilder: CWFolderBuilding? {
        set {
            imapStore.folderBuilder = newValue
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
        return CWIMAPStore.init(name: connectInfo.networkAddress,
                                port: UInt32(connectInfo.networkPort),
                                transport: connectInfo.connectionTransport!)
    }

    override open func start() {
        (service as! CWIMAPStore).maxPrefetchCount = maxPrefetchCount
        super.start()
    }

    open func openMailBox(_ name: String) {
        imapState.currentFolder = nil
        // Note: If you open a folder with PantomimeReadOnlyMode,
        // all messages will be prefetched by default,
        // independent of the prefetch parameter.
        if let folder = imapStore.folder(forName: name, mode: PantomimeReadWriteMode) {
            Log.info(component: comp, "openMailBox \(folder.name())")
        }
    }

    open func syncMails() throws {
        guard let folderName = imapState.currentFolder else {
            throw Constants.errorIllegalState(
                comp,
                stateName: NSLocalizedString("No open folder",
                    comment: "Need an open folder to sync mails"))
        }
        guard let folder = imapStore.folder(forName: imapState.currentFolder) else {
            throw Constants.errorFolderNotOpen(comp, folderName: folderName)
        }
        (folder as AnyObject).prefetch()
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
            Log.info(component: comp, "prefetched folder: \(folder.name())")
        } else {
            Log.info(component: comp, "folderPrefetchCompleted: \(notification)")
        }
        if let bq = folderBuilder?.backgroundQueue {
            // Wait until all newly synced mails are stored
            bq.waitUntilAllOperationsAreFinished()
        }
        delegate?.folderPrefetchCompleted(self, notification: notification)
    }

    @objc public func messagePrefetchCompleted(_ notification: Notification?) {
        dumpMethodName("messagePrefetchCompleted", notification: notification)
        delegate?.messagePrefetchCompleted(self, notification: notification)
    }

    @objc public func serviceInitialized(_ notification: Notification?) {
        dumpMethodName("serviceInitialized", notification: notification)

        imapStore.authenticate(connectInfo.loginName!,
                               password: connectInfo.loginPassword!,
                               mechanism: bestAuthMethod().rawValue)
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

        let unknownError = Constants.errorImapUnknown(comp)

        guard let userInfo = (notification as NSNotification?)?.userInfo else {
            delegate?.actionFailed(self, error: unknownError)
            return
        }
        guard let errorInfoDict = userInfo[PantomimeErrorInfo] as? NSDictionary else {
            delegate?.actionFailed(self, error: unknownError)
            return
        }
        guard let message = errorInfoDict[PantomimeBadResponseInfoKey] as? String else {
            delegate?.actionFailed(self, error: unknownError)
            return
        }

        delegate?.actionFailed(self, error: Constants.errorImapBadResponse(
            comp, response: message))
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
}

extension ImapSync: PantomimeFolderDelegate {
    @objc public func folderOpenCompleted(_ notification: Notification?) {
        if let folder: CWFolder = ((notification as NSNotification?)?.userInfo?["Folder"]
            as? CWFolder) {
            Log.info(component: comp, "folderOpenCompleted: \(folder.name())")
            imapState.currentFolder = folder.name()
        } else {
            Log.info(component: comp, "folderOpenCompleted: \(notification)")
            imapState.currentFolder = nil
        }
        delegate?.folderOpenCompleted(self, notification: notification)
    }

    @objc public func folderOpenFailed(_ notification: Notification?) {
        if let folder: CWFolder = ((notification as NSNotification?)?.userInfo?["Folder"]
            as? CWFolder) {
            Log.info(component: comp, "folderOpenFailed: \(folder.name())")
        } else {
            Log.info(component: comp, "folderOpenFailed: \(notification)")
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
