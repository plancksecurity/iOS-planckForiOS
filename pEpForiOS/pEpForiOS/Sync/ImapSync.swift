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
    var folderNames: [String] = []
}

public class ImapSync {
    private let comp = "ImapSync"

    let ErrorAuthenticationFailed = 1000
    let ErrorConnectionTimedOut = 1001

    private let defaultInboxName = "INBOX"

    private let connectInfo: ConnectInfo
    private var imapStore: CWIMAPStore
    private var imapState = ImapState()
    private var cache = EmailCacheManager()

    private var testOnlyCallback: (NSError? -> ())? = nil

    init(connectInfo: ConnectInfo) {
        self.connectInfo = connectInfo
        imapStore = CWIMAPStore.init(name: connectInfo.imapServerName,
                                     port: connectInfo.imapServerPort,
                                     transport: connectInfo.imapTransport)
        imapStore.setDelegate(self)
        imapStore.setLogger(Log.init())
    }

    deinit {
    }

    func start() {
        imapStore.connectInBackgroundAndNotify()
    }

    func test(block:(NSError? -> ())) {
        testOnlyCallback = block
        imapStore.connectInBackgroundAndNotify()
    }

    func openMailBox(name: String) {
        // Note: If you open a folder, all messages will be prefetched by default,
        // independent of the prefetch parameter.
        if let folder = imapStore.folderForName(defaultInboxName, mode: PantomimeReadOnlyMode,
                                                prefetch: false) {
            folder.setCacheManager(cache)
            Log.info(comp, "openMailBox \(folder.name())")
        }
    }

    @objc func handleFolders(timer: NSTimer?) {
        if let folderEnum = imapStore.folderEnumerator() {
            timer?.invalidate()
            imapState.folderNames = []
            for folder in folderEnum {
                let folderName = folder as! String
                imapState.folderNames.append(folderName)
            }
            Log.info(comp, "IMAP folders: \(imapState.folderNames)")
            openMailBox(defaultInboxName)
        }
    }

    /**
     Triggered by a timer after authentication completes, have to wait
     for folders to appear.
     */
    private func waitForFolders() {
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self,
                                                           selector: #selector(handleFolders),
                                                           userInfo: nil, repeats: true)
        timer.fire()
    }

    private func dumpMethodName(methodName: String, notification: NSNotification) {
        Log.info(comp, "\(methodName): \(notification)")
    }

    /**
     If this was just a test, and there was an error, invoke the test block with that error.
     */
    private func callTestBlock(error: NSError?) {
        if let block = testOnlyCallback {
            block(error)
        }
    }
}

extension ImapSync: CWServiceClient {
    @objc public func authenticationCompleted(notification: NSNotification) {
        dumpMethodName("authenticationCompleted", notification: notification)
        imapState.authenticationCompleted = true
        if let block = testOnlyCallback {
            block(nil)
        } else {
            waitForFolders()
        }
    }

    @objc public func authenticationFailed(notification: NSNotification) {
        dumpMethodName("authenticationFailed", notification: notification)
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
    }

    @objc public func connectionTerminated(notification: NSNotification) {
        dumpMethodName("connectionTerminated", notification: notification)
    }

    @objc public func connectionTimedOut(notification: NSNotification) {
        dumpMethodName("connectionTimedOut", notification: notification)
        let error = NSError.init(domain: comp, code: ErrorConnectionTimedOut,
                                 userInfo: [NSLocalizedDescriptionKey:
                                    NSLocalizedString("IMAP connection timed out",
                                        comment: "Error when testing IMAP account")])
        callTestBlock(error)
    }

    @objc public func folderPrefetchCompleted(notification: NSNotification) {
        dumpMethodName("folderPrefetchCompleted", notification: notification)
        if let folder: CWFolder = (notification.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "prefetched folder: \(folder.name())")
        } else {
            Log.info(comp, "folderPrefetchCompleted: \(notification)")
        }
    }

    @objc public func messagePrefetchCompleted(notification: NSNotification) {
        dumpMethodName("messagePrefetchCompleted", notification: notification)
    }

    @objc public func serviceInitialized(notification: NSNotification) {
        dumpMethodName("serviceInitialized", notification: notification)
        imapStore.authenticate(connectInfo.getImapUsername(),
                               password: connectInfo.imapPassword,
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
    }
}

extension ImapSync: PantomimeFolderDelegate {
    @objc public func folderOpenCompleted(notification: NSNotification!) {
        if let folder: CWFolder = (notification.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "folderOpenCompleted: \(folder.name())")
        } else {
            Log.info(comp, "folderOpenCompleted: \(notification)")
        }
    }

    @objc public func folderOpenFailed(notification: NSNotification!) {
        if let folder: CWFolder = (notification.userInfo?["Folder"] as! CWFolder) {
            Log.info(comp, "folderOpenFailed: \(folder.name())")
        } else {
            Log.info(comp, "folderOpenFailed: \(notification)")
        }
    }
}
