//
//  ImapConnection
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework
import PantomimeFramework
import pEpIOSToolbox
import CoreData

// MARK: - ImapState

extension ImapConnection {
    private struct State {
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
                    Log.shared.error("clearing hasError")
                }
            }
        }

        var currentFolderName: String?
        var currentFolder: CWIMAPFolder?
    }
}

class ImapConnection: ImapConnectionProtocol {
    static let defaultInboxName = "INBOX"

    var maxFetchCount: UInt = 50

    private var imapStore: CWIMAPStore

    private let connectInfo: EmailConnectInfo

    private var state = State()

    private let fallBackAuthMethod = AuthMethod.simple

    weak var delegate: ImapConnectionDelegate? {
        didSet {
            if delegate == nil {
                Log.shared.info("ImapSyncDelegate set to nil")
            }
        }
    }

    var isClientCertificateSet: Bool {
        return connectInfo.clientCertificate != nil
    }

    /// The access token, if authMethod is .saslXoauth2.
    /// - Note: Must be calculated once and stored, because its creation can lead to a login,
    ///   which may lead to multiple ones if calculated each time it's used.
    private let accessToken: OAuth2AccessTokenProtocol?

    init(connectInfo: EmailConnectInfo) {
        self.connectInfo = connectInfo
        imapStore = PantomimeStore(connectInfo: connectInfo)
        accessToken = connectInfo.accessToken()
        imapStore.setDelegate(self)
    }

    func listFolders() {
        imapStore.listFolders()
    }

    func start() {
        imapStore.maxFetchCount = maxFetchCount
        imapStore.connectInBackgroundAndNotify()
    }

    func cancel() {
        imapStore.cancelRequest()
    }

    @discardableResult func openMailBox(name: String,
                                        updateExistsCount: Bool = false) -> Bool {
        if let currentFolderName = state.currentFolderName,
            currentFolderName.isSameAs(otherFolderName: name) {
            state.currentFolder =
                imapStore.folder(forName: name,
                                 updateExistsCount: updateExistsCount) as? CWIMAPFolder
            return false
        } else {
            state.currentFolderName = nil
            state.currentFolder = nil
            // Note: If you a folder with PantomimeReadOnlyMode,
            // all messages will be fetched by default,
            // independent of the fetch parameter.
            let fol = imapStore.folder(forName: name,
                                       updateExistsCount: updateExistsCount) as? CWIMAPFolder
            state.currentFolder = fol
            if fol != nil {
                return true
            }
            return false
        }
    }

    private func bestAuthMethodFromList(_ mechanisms: [String])  -> AuthMethod {
        if mechanisms.count > 0 {
            let mechanismsLC = mechanisms.map() { mech in
                return mech.lowercased()
            }

            let s = Set(mechanismsLC)

            if s.contains("cram-md5") {
                return .cramMD5
            }

            // None of the auth mechanisms Patomime currently supports is supported by the server.
            // AUTH=LOGIN is not recommended at all, so a simple LOGIN command suffices.
            return fallBackAuthMethod
        } else {
            // no auth mechanisms have been provided by the server
            return fallBackAuthMethod
        }
    }

    private func bestAuthMethod() -> AuthMethod {
        return bestAuthMethodFromList(imapStore.supportedMechanisms() as? [String] ?? [])
    }

    private func openFolder(updateExistsCount: Bool) throws -> CWIMAPFolder {
        guard let folderName = state.currentFolderName else {
            throw BackgroundError.GeneralError.illegalState(info: #function)
        }
        guard let folder = imapStore.folder(forName: state.currentFolderName,
                                            updateExistsCount: updateExistsCount) else {
                                                throw BackgroundError
                                                    .GeneralError.illegalState(info: "\(type(of:self))- no folder: \(folderName)")
        }
        return folder as! CWIMAPFolder
    }

    private func startTLS() {
        state.state = .startedTLS
        imapStore.startTLS()
    }

    // MARK: - FETCH & SYNC

    func fetchMessages() throws {
        let folder = try openFolder(updateExistsCount: true)
        folder.fetch()
    }

    func fetchOlderMessages() throws {
        let folder = try openFolder(updateExistsCount: true)
        folder.fetchOlder()
    }

    func fetchUidsForNewMessages() throws {
        let folder = try openFolder(updateExistsCount: false)
        folder.fetchUidsForNewMailsIgnoringMessages(withHeaderDefined: [kPepHeaderAutoConsume])
    }

    func syncMessages(firstUID: UInt, lastUID: UInt, updateExistsCount: Bool = false) throws {
        let folder = try openFolder(updateExistsCount: updateExistsCount)
        folder.syncExistingFirstUID(firstUID, lastUID: lastUID)
    }

    // MARK: - FOLDERS

    func createFolderWithName(_ folderName: String) {
        // The only relevant parameter here is folderName, all others are
        // ignored by pantomime.
        imapStore.createFolder(withName: folderName, type: PantomimeFormatFolder,
                               contents: nil)
    }

    func deleteFolderWithName(_ folderName: String) {
        imapStore.deleteFolder(withName: folderName)
    }

    // MARK: - IDLE

    func sendIdle() {
        if state.hasError || !state.authenticationCompleted ||
            state.currentFolder == nil {
            return
        }
        imapStore.send(IMAP_IDLE, info: nil, string: "IDLE")
    }

    func exitIdle() {
        imapStore.exitIDLE()
    }

    // MARK: - EXPUNGE

    func expunge() throws {
        let folder = try openFolder(updateExistsCount: false)
        folder.expunge()
    }

    // MARK: - MOVE

    func moveMessage(uid: UInt, toFolderWithName: String) {
        let imapFolder = CWIMAPFolder(name: toFolderWithName)
        imapFolder.setStore(imapStore)
        imapFolder.moveMessage(withUid: uid, toFolderNamed: toFolderWithName)
    }

    // MARK: - STORE

    func store(info: [AnyHashable : Any], command: String) {
        imapStore.send(IMAP_UID_STORE, info: info, string: command)
    }

    // MARK: - COPY

    func copyMessage(uid: UInt, toFolderWithName: String) {
        let imapFolder = CWIMAPFolder(name: toFolderWithName)
        imapFolder.setStore(imapStore)
        imapFolder.copyMessage(withUid: uid, toFolderNamed: toFolderWithName)
    }

    // MARK: - APPEND

    func append(messageData: Data,
                folderType: FolderType, //!!!: pass CdFolder, not name and type
                folderName: String,
                internalDate: Date? = nil,
                context: NSManagedObjectContext) {
        let cwFolder = CWIMAPFolder(name: folderName)
        cwFolder.setStore(imapStore)
        var cwFlags: CWFlags? = nil
        let flags = folderType.defaultAppendImapFlags(context: context) //!!!: we are using ImapFlags here! (MMO) Create ticket for re-searching for hidden MMO usage in MM
        cwFlags = flags?.pantomimeFlags()
        cwFolder.appendMessage(fromRawSource: messageData,
                               flags: cwFlags,
                               internalDate: internalDate)
    }
}

// MARK: - DISPATCH TO INTERNAL STATE

extension ImapConnection {
    var hasError: Bool {
        get {
            return state.hasError
        }
        set {
            state.hasError = newValue
        }
    }

    var authenticationCompleted: Bool {
        return state.authenticationCompleted
    }

    var isIdling: Bool {
        return state.isIdling
    }

    func resetMatchedUIDs() {
        state.currentFolder?.resetMatchedUIDs()
    }

    func existingUIDs() -> Set<AnyHashable>? {
        return state.currentFolder?.existingUIDs()
    }
}

// MARK: - CLOSE

extension ImapConnection {
    // TODO: This is only called in tests, but accesses internal data.
    func close() {
        state.currentFolder = nil
        imapStore.close()
        imapStore.setDelegate(nil)
    }
}

// MARK: - DISPATCH TO CONNECTINFO

extension ImapConnection {
    func cdAccount(moc: NSManagedObjectContext) -> CdAccount? {
        return connectInfo.cdAccount(moc: moc)
    }

    func isTrusted(context: NSManagedObjectContext) -> Bool {
        return connectInfo.isTrusted(context: context)
    }

    var accountAddress: String {
        return connectInfo.account.address
    }
}

extension ImapConnection: CWServiceClient {
    public func badResponse(_ theNotification: Notification?) {
        let errorMsg = theNotification?.parseErrorMessageBadResponse()
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.badResponse(self, response: errorMsg)
        }
    }

    public func authenticationCompleted(_ notification: Notification?) { //BUFF: change to forward without needless notification
        state.authenticationCompleted = true
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.authenticationCompleted(self, notification: notification)
        }
    }

    public func authenticationFailed(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.authenticationFailed(self, notification: notification)
        }
    }

    public func connectionEstablished(_ notification: Notification?) {
    }

    public func connectionLost(_ notification: Notification?) {
        state.hasError = true
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.connectionLost(self, notification: notification)
        }
    }

    public func connectionTerminated(_ notification: Notification?) {
        state.hasError = true
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.connectionTerminated(self, notification: notification)
        }
    }

    public func connectionTimedOut(_ notification: Notification?) {
        state.hasError = true
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.connectionTimedOut(self, notification: notification)
        }
    }

    public func folderFetchCompleted(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderFetchCompleted(self, notification: notification)
        }
    }

    public func folderSyncCompleted(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderSyncCompleted(self, notification: notification)
        }
    }

    public func folderSyncFailed(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderSyncFailed(self, notification: notification)
        }
    }

    public func messagePrefetchCompleted(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.messagePrefetchCompleted(self, notification: notification)
        }
    }

    public func messageUidMoveCompleted(_ theNotification: Notification?) {
        runOnDelegate() { theDelegate in
            theDelegate.messageUidMoveCompleted(self, notification: theNotification)
        }
    }

    public func messageUidMoveFailed(_ theNotification: Notification?) {
        runOnDelegate() { theDelegate in
            theDelegate.messageUidMoveFailed(self, notification: theNotification)
        }
    }

    public func messagesCopyCompleted(_ theNotification: Notification?) {
        runOnDelegate() { theDelegate in
            theDelegate.messagesCopyCompleted(self, notification: theNotification)
        }
    }

    public func messagesCopyFailed(_ theNotification: Notification?) {
        runOnDelegate() { theDelegate in
            theDelegate.messagesCopyFailed(self, notification: theNotification)
        }
    }

    public func serviceInitialized(_ notification: Notification?) {
        if connectInfo.connectionTransport == ConnectionTransport.startTLS
            && !state.hasStartedTLS {
            startTLS()
        } else if connectInfo.authMethod == .saslXoauth2,
            let theLoginName = connectInfo.loginName,
            let token = accessToken {
            let authMechanism = connectInfo.authMethod.rawValue
            // The CWIMAPStore seems to expect that that its delegate (us) processes synchronously
            // and all work is done when returning. Thus we have to wait.
            let group = DispatchGroup()
            group.enter()
            token.performAction() { [weak self] error, freshToken in
                if let err = error {
                    Log.shared.error("%@", "\(err)")
                    if let theSelf = self {
                        theSelf.runOnDelegate(logName: #function) { theDelegate in
                            theDelegate.authenticationFailed(theSelf, notification: nil)
                        }
                    }
                    group.leave()
                } else {
                    guard let token = freshToken else {
                        group.leave()
                        return
                    }
                    // Our OAuthToken runs the competion handler on the main thread,
                    // thus we dispatch away from it.
                    let queue = DispatchQueue(label: "net.pep-security.pep4iOS.NetworkService.ImapService")
                    queue.async {
                        self?.imapStore.authenticate(theLoginName,
                                                     password: token,
                                                     mechanism: authMechanism)
                        group.leave()
                    }
                }
            }
            group.wait()
            return
        } else if let theLoginName = connectInfo.loginName,
            let theLoginPassword = connectInfo.loginPassword {
            imapStore.authenticate(theLoginName,
                                   password: theLoginPassword,
                                   mechanism: bestAuthMethod().rawValue)
        } else {
            Log.shared.error("IMAP: Want to log in, but neither have a login/password nor a token")

            runOnDelegate(logName: #function) { theDelegate in
                theDelegate.authenticationFailed(self, notification: notification)
            }
        }
    }

    public func serviceReconnected(_ theNotification: Notification?) {
    }

    public func messageChanged(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.messageChanged(self, notification: notification)
        }
    }

    public func folderStatusCompleted(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderStatusCompleted(self, notification: notification)
        }
    }

    public func actionFailed(_ notification: Notification?) {
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
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.messageStoreCompleted(self, notification: notification)
        }
    }

    public func messageStoreFailed(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.messageStoreFailed(self, notification: notification)
        }
    }

    public func folderCreateCompleted(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderCreateCompleted(self, notification: notification)
        }
    }

    public func folderCreateFailed(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderCreateFailed(self, notification: notification)
        }
    }

    public func folderDeleteCompleted(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderDeleteCompleted(self, notification: notification)
        }
    }

    public func folderDeleteFailed(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderDeleteFailed(self, notification: notification)
        }
    }

    public func idleEntered(_ notification: Notification?) {
        state.isIdling = true
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.idleEntered(self, notification: notification)
        }
    }

    public func idleNewMessages(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.idleNewMessages(self, notification: notification)
        }
    }

    public func idleFinished(_ notification: Notification?) {
        state.isIdling = false
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.idleFinished(self, notification: notification)
        }
    }
}

extension ImapConnection: PantomimeFolderDelegate {
    public func folderOpenCompleted(_ notification: Notification?) {
        if let folder: CWFolder = ((notification as NSNotification?)?.userInfo?["Folder"]
            as? CWFolder) {
            state.currentFolderName = folder.name()
        } else {
            state.currentFolderName = nil
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
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderListCompleted(self, notification: notification)
        }
    }

    public func folderNameParsed(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderNameParsed(self, notification: notification)
        }
    }

    public func folderAppendCompleted(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderAppendCompleted(self, notification: notification)
        }
    }

    public func folderAppendFailed(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderAppendFailed(self, notification: notification)
        }
    }

    public func folderExpungeCompleted(_ notification: Notification?) {
        runOnDelegate(logName: #function) { theDelegate in
            theDelegate.folderExpungeCompleted(self, notification: notification)
        }
    }
}

extension ImapConnection {
    private func runOnDelegate(logName: String = #function, block: (ImapConnectionDelegate) -> ()) {
        guard let del = delegate else  {
            // Treat the lack of a delegate as an error and force a reconnect.
            Log.shared.warn("No delegate for %@", logName)
            state.hasError = true
            return
        }
        block(del)
    }
}

extension String {
    func isSameAs(otherFolderName: String) -> Bool {
        if isInboxFolderName() && otherFolderName.isInboxFolderName() {
            return true
        }
        return self == otherFolderName
    }
}
