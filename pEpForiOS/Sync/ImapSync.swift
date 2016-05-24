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

public protocol ImapSyncDelegate {
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
    public func actionFailed(sync: ImapSync, error: NSError) {}
}

public enum ImapError: Int {
    case FolderNotOpen = 1000
}

public protocol IImapSync {
    /**
     The delegate.
     */
    var delegate: ImapSyncDelegate? { get set }

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
     - Todo: Make sure that prefetch actually syncs removed mails too.
     */
    func openMailBox(name: String, prefetchMails: Bool)

    /**
     Tries to fetch the the mail with the given UID from the folder with the given name.
     The folder must be currently opened!
     */
    func fetchMailFromFolderNamed(folderName: String, uid: Int)
}

public class ImapSync: Service, IImapSync {
    private let comp = "ImapSync"

    static public let defaultImapInboxName = "INBOX"

    public var delegate: ImapSyncDelegate?
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

    public func openMailBox(name: String, prefetchMails: Bool) {
        imapState.currentFolder = nil
        // Note: If you open a folder with PantomimeReadOnlyMode,
        // all messages will be prefetched by default,
        // independent of the prefetch parameter.
        if let folder = imapStore.folderForName(name, mode: PantomimeReadWriteMode,
                                                prefetch: prefetchMails) {
            Log.info(comp, "openMailBox \(folder.name())")
        }
    }

    public func fetchMailFromFolderNamed(folderName: String, uid: Int) {
        if folderName == imapState.currentFolder {
            imapStore.sendCommand(
                IMAP_UID_FETCH_HEADER_FIELDS_NOT, info: nil,
                string: String.init(format: "UID FETCH %u:%u BODY.PEEK[HEADER.FIELDS.NOT (From To Cc Subject Date Message-ID References In-Reply-To)]", uid, uid))
            imapStore.sendCommand(
                IMAP_UID_FETCH_BODY_TEXT, info: nil,
                string: String.init(format: "UID FETCH %u:%u BODY[TEXT]", uid, uid))
        } else {
            let error = NSError.init(
                domain: comp, code: ImapError.FolderNotOpen.rawValue,
                userInfo: [NSLocalizedDescriptionKey:
                    NSLocalizedString("Folder not open for fetching mail",
                        comment: "Error message when trying to fetch message from folder that ist not opened")])
            delegate?.actionFailed(self, error: error)
        }
    }

    private func dumpMethodName(methodName: String, notification: NSNotification?) {
        Log.info(comp, "\(methodName): \(notification)")
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
            Log.info(comp, "prefetched folder: \(folder.name())")
        } else {
            Log.info(comp, "folderPrefetchCompleted: \(notification)")
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
}

extension ImapSync: PantomimeFolderDelegate {
    @objc public func folderOpenCompleted(notification: NSNotification?) {
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "folderOpenCompleted: \(folder.name())")
            imapState.currentFolder = folder.name()
        } else {
            Log.info(comp, "folderOpenCompleted: \(notification)")
            imapState.currentFolder = nil
        }
        delegate?.folderOpenCompleted(self, notification: notification)
    }

    @objc public func folderOpenFailed(notification: NSNotification?) {
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "folderOpenFailed: \(folder.name())")
        } else {
            Log.info(comp, "folderOpenFailed: \(notification)")
        }
        delegate?.folderOpenFailed(self, notification: notification)
    }

    @objc public func folderListCompleted(notification: NSNotification?) {
        dumpMethodName("folderListCompleted", notification: notification)
        delegate?.folderListCompleted(self, notification: notification)
    }
}
