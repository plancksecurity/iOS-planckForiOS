//
//  ImapSync
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public struct ImapState {
    var authenticationCompleted = false
    var currentFolder: String?
}

public protocol ImapSyncDelegate: class {
    func authenticationCompleted(sync: ImapSync, notification: NSNotification?)
    func authenticationFailed(sync: ImapSync, notification: NSNotification?)
    func connectionLost(sync: ImapSync, notification: NSNotification?)
    func connectionTerminated(sync: ImapSync, notification: NSNotification?)
    func connectionTimedOut(sync: ImapSync, notification: NSNotification?)
    func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?)
    func messageChanged(sync: ImapSync, notification: NSNotification?)
    func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?)
    func folderOpenCompleted(sync: ImapSync, notification: NSNotification?)
    func folderOpenFailed(sync: ImapSync, notification: NSNotification?)
    func folderStatusCompleted(sync: ImapSync, notification: NSNotification?)
    func folderListCompleted(sync: ImapSync, notification: NSNotification?)
    func folderNameParsed(sync: ImapSync, notification: NSNotification?)
    func folderAppendCompleted(sync: ImapSync, notification: NSNotification?)
    func messageStoreCompleted(sync: ImapSync, notification: NSNotification?)
    func messageStoreFailed(sync: ImapSync, notification: NSNotification?)

    /** General error indicator */
    func actionFailed(sync: ImapSync, error: NSError)
}

/**
 Default implementation of a delegate that does nothing.
 */
public class DefaultImapSyncDelegate: ImapSyncDelegate {
    public init() {
    }

    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?)  {}
    public func authenticationFailed(sync: ImapSync, notification: NSNotification?)  {}
    public func connectionLost(sync: ImapSync, notification: NSNotification?)  {}
    public func connectionTerminated(sync: ImapSync, notification: NSNotification?)  {}
    public func connectionTimedOut(sync: ImapSync, notification: NSNotification?)  {}
    public func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?)  {}
    public func messageChanged(sync: ImapSync, notification: NSNotification?)  {}
    public func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?)  {}
    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?)  {}
    public func folderOpenFailed(sync: ImapSync, notification: NSNotification?)  {}
    public func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {}
    public func folderListCompleted(sync: ImapSync, notification: NSNotification?) {}
    public func folderNameParsed(sync: ImapSync, notification: NSNotification?) {}
    public func folderAppendCompleted(sync: ImapSync, notification: NSNotification?) {}
    public func messageStoreCompleted(sync: ImapSync, notification: NSNotification?) {}
    public func messageStoreFailed(sync: ImapSync, notification: NSNotification?) {}

    public func actionFailed(sync: ImapSync, error: NSError) {}
}

public enum ImapError: Int {
    case FolderNotOpen = 1000
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
    func openMailBox(name: String)

    /**
     Sync the mails from the curently selected folder.
     */
    func syncMails() throws

    /**
     Close the connection.
     */
    func close()
}

public class ImapSync: Service, IImapSync {
    public override var comp: String { get { return "ImapSync" } }

    static public let defaultImapInboxName = "INBOX"

    weak public var delegate: ImapSyncDelegate?
    public var maxPrefetchCount: UInt = 20

    public var folderBuilder: CWFolderBuilding? {
        set {
            imapStore.folderBuilder = newValue
        }
        get {
            return imapStore.folderBuilder
        }
    }

    public var folderNames: [String]? {
        if let folders = imapStore.folderEnumerator() {
            return folders.allObjects as? [String]
        }
        return nil
    }

    public var imapState = ImapState()

    var imapStore: CWIMAPStore {
        get {
            return service as! CWIMAPStore
        }
    }

    override func createService() -> CWService {
        return CWIMAPStore.init(name: connectInfo.imapServerName,
                                port: UInt32(connectInfo.imapServerPort),
                                transport: connectInfo.imapTransport)
    }

    override public func start() {
        (service as! CWIMAPStore).maxPrefetchCount = maxPrefetchCount
        super.start()
    }

    public func openMailBox(name: String) {
        imapState.currentFolder = nil
        // Note: If you open a folder with PantomimeReadOnlyMode,
        // all messages will be prefetched by default,
        // independent of the prefetch parameter.
        if let folder = imapStore.folderForName(name, mode: PantomimeReadWriteMode) {
            Log.infoComponent(comp, "openMailBox \(folder.name())")
        }
    }

    public func syncMails() throws {
        guard let folderName = imapState.currentFolder else {
            throw Constants.errorIllegalState(
                comp,
                stateName: NSLocalizedString("No open folder",
                    comment: "Need an open folder to sync mails"))
        }
        guard let folder = imapStore.folderForName(imapState.currentFolder) else {
            throw Constants.errorFolderNotOpen(comp, folderName: folderName)
        }
        folder.prefetch()
    }
}

extension ImapSync: CWServiceClient {
    @objc public func authenticationCompleted(notification: NSNotification?) {
        dumpMethodName("authenticationCompleted", notification: notification)
        imapState.authenticationCompleted = true
        delegate?.authenticationCompleted(self, notification: notification)
    }

    @objc public func authenticationFailed(notification: NSNotification?) {
        dumpMethodName("authenticationFailed", notification: notification)
        delegate?.authenticationFailed(self, notification: notification)
    }

    @objc public func connectionEstablished(notification: NSNotification?) {
        dumpMethodName("connectionEstablished", notification: notification)
    }

    @objc public func connectionLost(notification: NSNotification?) {
        dumpMethodName("connectionLost", notification: notification)
        imapState.authenticationCompleted = false
        delegate?.connectionLost(self, notification: notification)
    }

    @objc public func connectionTerminated(notification: NSNotification?) {
        dumpMethodName("connectionTerminated", notification: notification)
        imapState.authenticationCompleted = false
        delegate?.connectionTerminated(self, notification: notification)
    }

    @objc public func connectionTimedOut(notification: NSNotification?) {
        dumpMethodName("connectionTimedOut", notification: notification)
        imapState.authenticationCompleted = false
        delegate?.connectionTimedOut(self, notification: notification)
    }

    @objc public func folderPrefetchCompleted(notification: NSNotification?) {
        dumpMethodName("folderPrefetchCompleted", notification: notification)
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.infoComponent(comp, "prefetched folder: \(folder.name())")
        } else {
            Log.infoComponent(comp, "folderPrefetchCompleted: \(notification)")
        }
        if let bq = folderBuilder?.backgroundQueue {
            // Wait until all newly synced mails are stored
            bq.waitUntilAllOperationsAreFinished()
        }
        delegate?.folderPrefetchCompleted(self, notification: notification)
    }

    @objc public func messagePrefetchCompleted(notification: NSNotification?) {
        dumpMethodName("messagePrefetchCompleted", notification: notification)
        delegate?.messagePrefetchCompleted(self, notification: notification)
    }

    @objc public func serviceInitialized(notification: NSNotification?) {
        dumpMethodName("serviceInitialized", notification: notification)

        // The password from connectInfo has precedence over the keychain, for unit test
        var password: String?
        if let pass = connectInfo.imapPassword {
            password = pass
        } else {
            password = KeyChain.getPassword(connectInfo.email,
                                            serverType: Account.AccountType.IMAP.asString())
        }

        imapStore.authenticate(connectInfo.getImapUsername(),
                               password: password!,
                               mechanism: bestAuthMethod().rawValue)
    }

    @objc public func serviceReconnected(theNotification: NSNotification?) {
        dumpMethodName("serviceReconnected", notification: theNotification)
    }

    @objc public func service(theService: CWService, sentData theData: NSData) {
    }

    @objc public func service(theService: CWService, receivedData theData: NSData) {
    }

    @objc public func messageChanged(notification: NSNotification?) {
        dumpMethodName("messageChanged", notification: notification)
        delegate?.messageChanged(self, notification: notification)
    }

    @objc public func folderStatusCompleted(notification: NSNotification?) {
        dumpMethodName("folderStatusCompleted", notification: notification)
        delegate?.folderStatusCompleted(self, notification: notification)
    }

    @objc public func actionFailed(notification: NSNotification?) {
        dumpMethodName("actionFailed", notification: notification)

        let unknownError = Constants.errorImapUnknown(comp)

        guard let userInfo = notification?.userInfo else {
            delegate?.actionFailed(self, error: unknownError)
            return
        }
        guard let errorInfoDict = userInfo[PantomimeErrorInfo] else {
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

    @objc public func messageStoreCompleted(notification: NSNotification?) {
        dumpMethodName("messageStoreCompleted", notification: notification)
        delegate?.messageStoreCompleted(self, notification: notification)
    }

    @objc public func messageStoreFailed(notification: NSNotification?) {
        dumpMethodName("messageStoreFailed", notification: notification)
        delegate?.messageStoreFailed(self, notification: notification)
    }
}

extension ImapSync: PantomimeFolderDelegate {
    @objc public func folderOpenCompleted(notification: NSNotification?) {
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.infoComponent(comp, "folderOpenCompleted: \(folder.name())")
            imapState.currentFolder = folder.name()
        } else {
            Log.infoComponent(comp, "folderOpenCompleted: \(notification)")
            imapState.currentFolder = nil
        }
        delegate?.folderOpenCompleted(self, notification: notification)
    }

    @objc public func folderOpenFailed(notification: NSNotification?) {
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.infoComponent(comp, "folderOpenFailed: \(folder.name())")
        } else {
            Log.infoComponent(comp, "folderOpenFailed: \(notification)")
        }
        delegate?.folderOpenFailed(self, notification: notification)
    }

    @objc public func folderListCompleted(notification: NSNotification?) {
        dumpMethodName("folderListCompleted", notification: notification)
        delegate?.folderListCompleted(self, notification: notification)
    }

    @objc public func folderNameParsed(notification: NSNotification?) {
        dumpMethodName("folderNameParsed", notification: notification)
        delegate?.folderNameParsed(self, notification: notification)
    }

    @objc public func folderAppendCompleted(notification: NSNotification?) {
        dumpMethodName("folderAppendCompleted", notification: notification)
        delegate?.folderAppendCompleted(self, notification: notification)
    }
}