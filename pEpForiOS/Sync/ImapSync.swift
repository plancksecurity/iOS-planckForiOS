//
//  ImapSync
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

struct ImapState {
    var authenticationCompleted = false
}

public protocol ImapSyncDelegate {
    func receivedFolderNames(sync: ImapSync, folderNames: [String])

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
}

/**
 Default implementation of a delegate that does nothing.
 */
public class DefaultImapSyncDelegate: ImapSyncDelegate {
    public init() {
    }

    public func receivedFolderNames(sync: ImapSync, folderNames: [String]) {}
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
     Start to connect.
     */
    func start()

    /**
     Triggers a timer after authentication completes, have to wait
     for folders to appear.
     Should call this after receiving authenticationCompleted()
     */
    func waitForFolders()

    /**
     Opens the folder with the given name, prefetching all emails contained if wanted.
     Should call this after receiving receivedFolderNames().
     */
    func openMailBox(name: String, prefetchMails: Bool)
}

public class ImapSync: Service, IImapSync {
    private let comp = "ImapSync"

    static public let defaultImapInboxName = "INBOX"

    public var cache: EmailCache?
    public var delegate: ImapSyncDelegate?
    public var folderBuilder: CWFolderBuilding? {
        set {
            imapStore.folderBuilder = newValue
        }
        get {
            return imapStore.folderBuilder
        }
    }

    private var imapState = ImapState()

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
        // Note: If you open a folder with PantomimeReadOnlyMode,
        // all messages will be prefetched by default,
        // independent of the prefetch parameter.
        if let folder = imapStore.folderForName(name, mode: PantomimeReadWriteMode,
                                                prefetch: prefetchMails) {
            if cache != nil {
                folder.setCacheManager(cache!)
            }
            Log.info(comp, "openMailBox \(folder.name())")
        }
    }

    @objc func handleFolders(timer: NSTimer?) {
        if let folderEnum = imapStore.folderEnumerator() {
            timer?.invalidate()
            var folderNames: [String] = []
            for folder in folderEnum {
                let folderName = folder as! String
                folderNames.append(folderName)
            }
            delegate?.receivedFolderNames(self, folderNames: folderNames)
        }
    }

    /**
     Triggers a timer after authentication completes, have to wait
     for folders to appear.
     */
    public func waitForFolders() {
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self,
                                                           selector: #selector(handleFolders),
                                                           userInfo: nil, repeats: true)
        timer.fire()
    }

    private func dumpMethodName(methodName: String, notification: NSNotification?) {
        Log.info(comp, "\(methodName): \(notification)")
    }
}

extension ImapSync: CWServiceClient {
    @objc public func authenticationCompleted(notification: NSNotification) {
        dumpMethodName("authenticationCompleted", notification: notification)
        imapState.authenticationCompleted = true
        delegate?.authenticationCompleted(self, notification: notification)
        if (isJustATest) {
            callTestBlock(nil)
        }
    }

    @objc public func authenticationFailed(notification: NSNotification) {
        dumpMethodName("authenticationFailed", notification: notification)
        delegate?.authenticationFailed(self, notification: notification)
        let error = NSError.init(domain: comp, code: ErrorAuthenticationFailed,
                                 userInfo: [NSLocalizedDescriptionKey:
                                    NSLocalizedString("IMAP authentication failed",
                                        comment: "Error when testing IMAP account")])
        callTestBlock(error)
    }

    @objc public func connectionEstablished(notification: NSNotification) {
        dumpMethodName("connectionEstablished", notification: notification)
    }

    @objc public func connectionLost(notification: NSNotification) {
        dumpMethodName("connectionLost", notification: notification)
        delegate?.connectionLost(self, notification: notification)
    }

    @objc public func connectionTerminated(notification: NSNotification) {
        dumpMethodName("connectionTerminated", notification: notification)
        delegate?.connectionTerminated(self, notification: notification)
    }

    @objc public func connectionTimedOut(notification: NSNotification) {
        dumpMethodName("connectionTimedOut", notification: notification)
        delegate?.connectionTimedOut(self, notification: notification)
        let error = NSError.init(domain: comp, code: ErrorConnectionTimedOut,
                                 userInfo: [NSLocalizedDescriptionKey:
                                    NSLocalizedString("IMAP connection timed out",
                                        comment: "Error when testing IMAP account")])
        callTestBlock(error)
    }

    @objc public func folderPrefetchCompleted(notification: NSNotification?) {
        dumpMethodName("folderPrefetchCompleted", notification: notification)
        delegate?.folderPrefetchCompleted(self, notification: notification)
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "prefetched folder: \(folder.name())")
        } else {
            Log.info(comp, "folderPrefetchCompleted: \(notification)")
        }
    }

    @objc public func messagePrefetchCompleted(notification: NSNotification) {
        dumpMethodName("messagePrefetchCompleted", notification: notification)
        delegate?.messagePrefetchCompleted(self, notification: notification)
    }

    @objc public func serviceInitialized(notification: NSNotification) {
        dumpMethodName("serviceInitialized", notification: notification)
        let password = KeyChain.getPassword(connectInfo.email,
                                            serverType: Account.AccountType.Imap.asString())
        imapStore.authenticate(connectInfo.getImapUsername(),
                               password: password,
                               mechanism: connectInfo.imapAuthMethod)
    }

    @objc public func serviceReconnected(theNotification: NSNotification!) {
        dumpMethodName("serviceReconnected", notification: theNotification)
    }

    @objc public func service(theService: CWService!, sentData theData: NSData!) {
    }

    @objc public func service(theService: CWService!, receivedData theData: NSData!) {
    }

    @objc public func messageChanged(notification: NSNotification) {
        dumpMethodName("messageChanged", notification: notification)
        delegate?.messageChanged(self, notification: notification)
    }
}

extension ImapSync: PantomimeFolderDelegate {
    @objc public func folderOpenCompleted(notification: NSNotification?) {
        delegate?.folderOpenCompleted(self, notification: notification)
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "folderOpenCompleted: \(folder.name())")
        } else {
            Log.info(comp, "folderOpenCompleted: \(notification)")
        }
    }

    @objc public func folderOpenFailed(notification: NSNotification?) {
        delegate?.folderOpenFailed(self, notification: notification)
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "folderOpenFailed: \(folder.name())")
        } else {
            Log.info(comp, "folderOpenFailed: \(notification)")
        }
    }
}
