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
    func receivedFolderNames(folderNames: [String])

    func authenticationCompleted(notification: NSNotification?)
    func authenticationFailed(notification: NSNotification?)
    func connectionLost(notification: NSNotification?)
    func connectionTerminated(notification: NSNotification?)
    func connectionTimedOut(notification: NSNotification?)
    func folderPrefetchCompleted(notification: NSNotification?)
    func messageChanged(notification: NSNotification?)
    func messagePrefetchCompleted(notification: NSNotification?)
    func folderOpenCompleted(notification: NSNotification?)
    func folderOpenFailed(notification: NSNotification?)

}

protocol IImapSync {
    /**
     The delegate.
     */
    var delegate: ImapSyncDelegate? { get set }

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
     Opens the folder with the given name, prefetching all emails contained.
     Should call this after receiving receivedFolderNames().
     */
    func openMailBox(name: String)
}

public class ImapSync: Service, IImapSync {
    private let comp = "ImapSync"

    static public let defaultImapInboxName = "INBOX"

    private var imapState = ImapState()
    public var cache: EmailCache?
    public var delegate: ImapSyncDelegate?
    var folderBuilder: CWFolderBuilding? {
        set {
            imapStore.folderBuilder = newValue
        }
        get {
            return imapStore.folderBuilder
        }
    }

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

    func openMailBox(name: String) {
        // Note: If you open a folder with PantomimeReadOnlyMode,
        // all messages will be prefetched by default,
        // independent of the prefetch parameter.
        if let folder = imapStore.folderForName(name, mode: PantomimeReadWriteMode,
                                                prefetch: true) {
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
            delegate?.receivedFolderNames(folderNames)
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
        delegate?.authenticationCompleted(notification)
        if (isJustATest) {
            callTestBlock(nil)
        }
    }

    @objc public func authenticationFailed(notification: NSNotification) {
        dumpMethodName("authenticationFailed", notification: notification)
        delegate?.authenticationFailed(notification)
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
        delegate?.connectionLost(notification)
    }

    @objc public func connectionTerminated(notification: NSNotification) {
        dumpMethodName("connectionTerminated", notification: notification)
        delegate?.connectionTerminated(notification)
    }

    @objc public func connectionTimedOut(notification: NSNotification) {
        dumpMethodName("connectionTimedOut", notification: notification)
        delegate?.connectionTimedOut(notification)
        let error = NSError.init(domain: comp, code: ErrorConnectionTimedOut,
                                 userInfo: [NSLocalizedDescriptionKey:
                                    NSLocalizedString("IMAP connection timed out",
                                        comment: "Error when testing IMAP account")])
        callTestBlock(error)
    }

    @objc public func folderPrefetchCompleted(notification: NSNotification?) {
        dumpMethodName("folderPrefetchCompleted", notification: notification)
        delegate?.folderPrefetchCompleted(notification)
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "prefetched folder: \(folder.name())")
        } else {
            Log.info(comp, "folderPrefetchCompleted: \(notification)")
        }
    }

    @objc public func messagePrefetchCompleted(notification: NSNotification) {
        dumpMethodName("messagePrefetchCompleted", notification: notification)
        delegate?.messagePrefetchCompleted(notification)
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
        delegate?.messageChanged(notification)
    }
}

extension ImapSync: PantomimeFolderDelegate {
    @objc public func folderOpenCompleted(notification: NSNotification?) {
        delegate?.folderOpenCompleted(notification)
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "folderOpenCompleted: \(folder.name())")
        } else {
            Log.info(comp, "folderOpenCompleted: \(notification)")
        }
    }

    @objc public func folderOpenFailed(notification: NSNotification?) {
        delegate?.folderOpenFailed(notification)
        if let folder: CWFolder = (notification?.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "folderOpenFailed: \(folder.name())")
        } else {
            Log.info(comp, "folderOpenFailed: \(notification)")
        }
    }
}
