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
    func folderFetchCompleted(_ sync: ImapSync, notification: Notification?)
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
    func messageUidMoveCompleted(_ sync: ImapSync, notification: Notification?)
    func messageUidMoveFailed(_ sync: ImapSync, notification: Notification?)
    func messagesCopyCompleted(_ sync: ImapSync, notification: Notification?)
    func messagesCopyFailed(_ sync: ImapSync, notification: Notification?)
    func folderCreateCompleted(_ sync: ImapSync, notification: Notification?)
    func folderCreateFailed(_ sync: ImapSync, notification: Notification?)
    func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?)
    func folderDeleteFailed(_ sync: ImapSync, notification: Notification?)
    func badResponse(_ sync: ImapSync, response: String?)
    func actionFailed(_ sync: ImapSync, response: String?)
    func idleEntered(_ sync: ImapSync, notification: Notification?)
    func idleNewMessages(_ sync: ImapSync, notification: Notification?)
    func idleFinished(_ sync: ImapSync, notification: Notification?)
}

open class ImapSync: Service {
    public struct ImapState {
        enum State {
            case initial
            case startedTLS
            case authenticated
            case idling
            case error
        }
        var state: State = .initial

        var hasStartedTLS: Bool {
            get {
                return state == .startedTLS
            }
        }

        var authenticationCompleted: Bool {
            get {
                return state == .authenticated || state == .idling
            }
            set {
                if newValue {
                    state = .authenticated
                } else {
                    state = .initial
                }
            }
        }

        var isIdling: Bool {
            get {
                return state == .idling
            }
            set {
                if newValue {
                    state = .idling
                } else {
                    state = .authenticated
                }
            }
        }

        var hasError: Bool {
            get {
                return state == .error
            }
            set {
                if newValue {
                    state = .error
                } else {
                    Logger.backendLogger.error("clearing hasError")
                }
            }
        }

        var currentFolderName: String?
        var currentFolder: CWIMAPFolder?
    }

    open override var comp: String { get { return "ImapSync" } }

    static public let defaultImapInboxName = "INBOX"

    let nonExistantMailboxName = MessageID.generate()

    weak open var delegate: ImapSyncDelegate?

    open var maxFetchCount: UInt = 20

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
        (service as! CWIMAPStore).maxFetchCount = maxFetchCount
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

    /// Opens the given mailbox (by name).  If already open and exists count does not matter,
    /// do nothing.
    ///
    /// - Parameters:
    ///   - name: name of mailbox to open
    ///   - updateExistsCount: if true, exists count of the mailbox is updated
    /// - Returns: true if the mailbox had to be opened, false if it already was open.
    @discardableResult open func openMailBox(name: String,
                                             updateExistsCount: Bool = false) -> Bool {
        if let currentFolderName = imapState.currentFolderName,
            currentFolderName.isSameAs(otherFolderName: name) {
            imapState.currentFolder =
                imapStore.folder(forName: name,
                                 updateExistsCount: updateExistsCount) as? CWIMAPFolder
            return false
        } else {
            imapState.currentFolderName = nil
            imapState.currentFolder = nil
            // Note: If you open a folder with PantomimeReadOnlyMode,
            // all messages will be fetched by default,
            // independent of the fetch parameter.
            let fol = imapStore.folder(forName: name,
                                       updateExistsCount: updateExistsCount) as? CWIMAPFolder
            imapState.currentFolder = fol
            if fol != nil {
                return true
            }
            return false
        }
    }

    private func openFolder(updateExistsCount: Bool) throws -> CWIMAPFolder {
        guard let folderName = imapState.currentFolderName else {
            throw BackgroundError.GeneralError.illegalState(info: #function)
        }
        guard let folder = imapStore.folder(forName: imapState.currentFolderName,
                                            updateExistsCount: updateExistsCount) else {
            throw BackgroundError
                .GeneralError.illegalState(info: "\(comp)- no folder: \(folderName)")
        }
        return folder as! CWIMAPFolder
    }

    private func startTLS() {
        imapState.state = .startedTLS
        imapStore.startTLS()
    }

    // MARK: - FETCH & SYNC

    open func fetchMessages() throws {
        let folder = try openFolder(updateExistsCount: true)
        folder.fetch()
    }

    open func fetchOlderMessages() throws {
        let folder = try openFolder(updateExistsCount: true)
        folder.fetchOlder()
    }

    open func fetchUidsForNewMessages() throws {
        let folder = try openFolder(updateExistsCount: false)
        folder.fetchUidsForNewMails()
    }

    open func syncMessages(firstUID: UInt, lastUID: UInt, updateExistsCount: Bool = false) throws {
        let folder = try openFolder(updateExistsCount: updateExistsCount)
        folder.syncExistingFirstUID(firstUID, lastUID: lastUID)
    }

    // MARK: - FOLDERS

    open func createFolderWithName(_ folderName: String) {
        // The only relevant parameter here is folderName, all others are
        // ignored by pantomime.
        imapStore.createFolder(withName: folderName, type: PantomimeFormatFolder,
                                       contents: nil)
    }

    open func deleteFolderWithName(_ folderName: String) {
        imapStore.deleteFolder(withName: folderName)
    }

    // MARK: - IDLE

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

    // MARK: - HELPER

    private func runOnDelegate(logName: String = #function, block: (ImapSyncDelegate) -> ()) {
        guard let del = delegate else  {
            Logger.backendLogger.warn("No delegate")
            return
        }
        block(del)
    }
}

extension ImapSync: CWServiceClient {
    public func badResponse(_ theNotification: Notification?) {
        dumpMethodName(#function, notification: theNotification)
        let errorMsg = theNotification?.parseErrorMessageBadResponse()
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.badResponse(self, response: errorMsg)
        }
    }

    public func authenticationCompleted(_ notification: Notification?) {
        dumpMethodName("authenticationCompleted", notification: notification)
        imapState.authenticationCompleted = true
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.authenticationCompleted(self, notification: notification)
        }
    }

    public func authenticationFailed(_ notification: Notification?) {
        dumpMethodName("authenticationFailed", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.authenticationFailed(self, notification: notification)
        }
    }

    public func connectionEstablished(_ notification: Notification?) {
        dumpMethodName("connectionEstablished", notification: notification)
    }

    public func connectionLost(_ notification: Notification?) {
        dumpMethodName("connectionLost", notification: notification)
        imapState.authenticationCompleted = false
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.connectionLost(self, notification: notification)
        }
    }

    public func connectionTerminated(_ notification: Notification?) {
        dumpMethodName("connectionTerminated", notification: notification)
        imapState.authenticationCompleted = false
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.connectionTerminated(self, notification: notification)
        }
    }

    public func connectionTimedOut(_ notification: Notification?) {
        dumpMethodName("connectionTimedOut", notification: notification)
        imapState.authenticationCompleted = false
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.connectionTimedOut(self, notification: notification)
        }
    }

    public func folderFetchCompleted(_ notification: Notification?) {
        dumpMethodName("folderFetchCompleted", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderFetchCompleted(self, notification: notification)
        }
    }

    public func folderSyncCompleted(_ notification: Notification?) {
        dumpMethodName("folderSyncCompleted", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderSyncCompleted(self, notification: notification)
        }
    }
    
    public func folderSyncFailed(_ notification: Notification?) {
        dumpMethodName("folderSyncFailed", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderSyncFailed(self, notification: notification)
        }
    }

    public func messagePrefetchCompleted(_ notification: Notification?) {
        dumpMethodName("messagePrefetchCompleted", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.messagePrefetchCompleted(self, notification: notification)
        }
    }

    public func messageUidMoveCompleted(_ theNotification: Notification?) {
        dumpMethodName("messageUidMoveCompleted", notification: theNotification)
        runOnDelegate() { theDelegate in
            theDelegate.messageUidMoveCompleted(self, notification: theNotification)
        }
    }

    public func messageUidMoveFailed(_ theNotification: Notification?) {
        dumpMethodName("messageUidMoveFailed", notification: theNotification)
        runOnDelegate() { theDelegate in
            theDelegate.messageUidMoveFailed(self, notification: theNotification)
        }
    }

    public func messagesCopyCompleted(_ theNotification: Notification?) {
        dumpMethodName("messagesCopyCompleted", notification: theNotification)
        runOnDelegate() { theDelegate in
            theDelegate.messagesCopyCompleted(self, notification: theNotification)
        }
    }

    public func messagesCopyFailed(_ theNotification: Notification?) {
        dumpMethodName("messagesCopyFailed", notification: theNotification)
        runOnDelegate() { theDelegate in
            theDelegate.messagesCopyFailed(self, notification: theNotification)
        }
    }

    public func serviceInitialized(_ notification: Notification?) {
        dumpMethodName("serviceInitialized", notification: notification)
        
        if connectInfo.connectionTransport == ConnectionTransport.startTLS
            && !imapState.hasStartedTLS {
            startTLS()
        } else if
            let authMethod = connectInfo.authMethod,
            authMethod == .saslXoauth2,
            let loginName = connectInfo.loginName,
            let token = connectInfo.accessToken {
            // The CWIMAPStore seems to expect that that its delegate (us) processes synchronously
            // and all work is done when returning. Thus we have to wait.
            let group = DispatchGroup()
            group.enter()
            token.performAction() { [weak self] error, freshToken in
                if let err = error {
                    Logger.backendLogger.error("%{public}@", err.localizedDescription)
                    if let theSelf = self {
                        theSelf.runOnDelegate(logName: #function) { theDelegate in
                            theDelegate.authenticationFailed(theSelf, notification: nil)
                        }
                    }
                    group.leave()
                } else {
                    // Our OAuthToken runs the competion handler on the main thread,
                    // thus we dispatch away from it.
                    let queue = DispatchQueue(label: "net.pep-security.pep4iOS.NetworkService.ImapService")
                    queue.async {
                        self?.imapStore.authenticate(
                            loginName, password: freshToken, mechanism: authMethod.rawValue)
                        group.leave()
                    }
                }
            }
            group.wait()
            return
        } else if let loginName = connectInfo.loginName,
            let loginPassword = connectInfo.loginPassword {
            imapStore.authenticate(
                loginName, password: loginPassword, mechanism: bestAuthMethod().rawValue)
        } else {
            if connectInfo.loginPassword == nil {
                Logger.backendLogger.error("Want to login, but don't have a password")
            }
            if connectInfo.loginName == nil {
                Logger.backendLogger.error("Want to login, but don't have a login")
            }
            runOnDelegate(logName: #function) { theDelegate in
                theDelegate.authenticationFailed(self, notification: notification)
            }
        }
    }

    public func serviceReconnected(_ theNotification: Notification?) {
        dumpMethodName("serviceReconnected", notification: theNotification)
    }

    public func messageChanged(_ notification: Notification?) {
        dumpMethodName("messageChanged", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.messageChanged(self, notification: notification)
        }
    }

    public func folderStatusCompleted(_ notification: Notification?) {
        dumpMethodName("folderStatusCompleted", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderStatusCompleted(self, notification: notification)
        }
    }

    public func actionFailed(_ notification: Notification?) {
        dumpMethodName("actionFailed", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            guard
                let userInfo = (notification as NSNotification?)?.userInfo,
                let errorInfoDict = userInfo[PantomimeErrorInfo] as? NSDictionary,
                let responseString = errorInfoDict[PantomimeBadResponseInfoKey] as? String
                else {
                    delegate?.badResponse(self, response: nil)
                    return
            }
            theDelegate.badResponse(self, response: responseString)
        }
    }

    public func messageStoreCompleted(_ notification: Notification?) {
        dumpMethodName("messageStoreCompleted", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.messageStoreCompleted(self, notification: notification)
        }
    }

    public func messageStoreFailed(_ notification: Notification?) {
        dumpMethodName("messageStoreFailed", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.messageStoreFailed(self, notification: notification)
        }
    }

    public func folderCreateCompleted(_ notification: Notification?) {
        dumpMethodName("folderCreateCompleted", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderCreateCompleted(self, notification: notification)
        }
    }

    public func folderCreateFailed(_ notification: Notification?) {
        dumpMethodName("folderCreateFailed", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderCreateFailed(self, notification: notification)
        }
    }

    public func folderDeleteCompleted(_ notification: Notification?) {
        dumpMethodName("folderDeleteCompleted", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderDeleteCompleted(self, notification: notification)
        }
    }

    public func folderDeleteFailed(_ notification: Notification?) {
        dumpMethodName("folderDeleteFailed", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderDeleteFailed(self, notification: notification)
        }
    }

    public func idleEntered(_ notification: Notification?) {
        dumpMethodName("idleEntered", notification: notification)
        imapState.isIdling = true
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.idleEntered(self, notification: notification)
        }
    }

    public func idleNewMessages(_ notification: Notification?) {
        dumpMethodName("idleNewMessages", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.idleNewMessages(self, notification: notification)
        }
    }

    public func idleFinished(_ notification: Notification?) {
        dumpMethodName("idleFinished", notification: notification)
        imapState.isIdling = false
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.idleFinished(self, notification: notification)
        }
    }
}

extension ImapSync: PantomimeFolderDelegate {
    public func folderOpenCompleted(_ notification: Notification?) {
        if let folder: CWFolder = ((notification as NSNotification?)?.userInfo?["Folder"]
            as? CWFolder) {
            imapState.currentFolderName = folder.name()
        } else {
            imapState.currentFolderName = nil
        }
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderOpenCompleted(self, notification: notification)
        }
    }

    public func folderOpenFailed(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderOpenFailed(self, notification: notification)
        }
    }

    public func folderListCompleted(_ notification: Notification?) {
        dumpMethodName("folderListCompleted", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderListCompleted(self, notification: notification)
        }
    }

    public func folderNameParsed(_ notification: Notification?) {
        dumpMethodName("folderNameParsed", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderNameParsed(self, notification: notification)
        }
    }

    public func folderAppendCompleted(_ notification: Notification?) {
        dumpMethodName("folderAppendCompleted", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderAppendCompleted(self, notification: notification)
        }
    }

    public func folderAppendFailed(_ notification: Notification?) {
        dumpMethodName("folderAppendFailed", notification: notification)
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderAppendFailed(self, notification: notification)
        }
    }
}

extension String {
    func isInboxFolderName() -> Bool {
        if lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            return true
        }
        return false
    }

    func isSameAs(otherFolderName: String) -> Bool {
        if isInboxFolderName() && otherFolderName.isInboxFolderName() {
            return true
        }
        return self == otherFolderName
    }
}
